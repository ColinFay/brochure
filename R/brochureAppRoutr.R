# "brochure", "/brochure/" and "/brochure" all mean the same mount.
normalize_basepath <- function(basepath) {
  bp <- gsub("^/+|/+$", "", basepath)
  if (nzchar(bp)) {
    paste0("/", bp)
  } else {
    ""
  }
}

# Some reverse proxies strip the mount before forwarding (Posit Connect does),
# others pass it through. Drop it here so a page href matches either way.
strip_basepath <- function(path, basepath) {
  if (!nzchar(basepath) || !startsWith(path, basepath)) {
    return(path)
  }
  rest <- substring(path, nchar(basepath) + 1)
  if (!nzchar(rest)) {
    return("/")
  }
  if (startsWith(rest, "/")) {
    rest
  } else {
    path
  }
}

on_connect <- function() {
  identical(Sys.getenv("RSTUDIO_PRODUCT"), "CONNECT") ||
    identical(Sys.getenv("POSIT_PRODUCT"), "CONNECT")
}

# Determine the external mount path of the app (the part the reverse proxy
# serves it under). Posit Connect sends it on every request, GET and websocket
# alike, as the `RStudio-Connect-App-Base-URL` header -- observed as
# "https://<host>/content/<guid>", with `SCRIPT_NAME` left empty, so the header
# is the only source Connect gives us. Falls back to the `basepath` argument,
# then to "" (app served at the domain root, e.g. local dev).
get_mount <- function(req, basepath = "") {
  base_url <- req[["HTTP_RSTUDIO_CONNECT_APP_BASE_URL"]]
  # The header is only believed when the app really runs on Connect: anywhere
  # else a client sends it at will, and it decides the prefix every URL of the
  # page is rewritten with. The extracted path is kept to a plain path too.
  if (on_connect() && !is.null(base_url) && nzchar(base_url)) {
    path <- sub("^[a-zA-Z][a-zA-Z0-9+.-]*://[^/]+", "", base_url)
    path <- sub("/+$", "", path)
    if (grepl("^/[A-Za-z0-9/_-]+$", path)) {
      return(path)
    }
  }
  normalize_basepath(basepath)
}

# The websocket handshake of a page hits `<href>/websocket/`; drop that suffix
# to get back the href of the page the session belongs to.
page_path <- function(path) {
  sub("websocket/?$", "", path)
}

# routr dispatches on a Rook environment: hand it a copy of `req` with
# `PATH_INFO` swapped, so a page can be looked up by a path other than the
# requested one (and without mutating Shiny's own request object).
req_with_path <- function(req, path) {
  out <- as.environment(
    as.list(req, all.names = TRUE)
  )
  out$PATH_INFO <- path
  out$.__reqres_Request__ <- NULL
  out
}

# Run `req` through a list of req handlers. A handler returning an httpResponse
# short-circuits: that response is sent to the browser as is.
run_req_handlers <- function(req, handlers) {
  for (handler in handlers) {
    req <- handler(req)
    if (inherits(req, "httpResponse")) {
      return(req)
    }
  }
  req
}

run_res_handlers <- function(res, req, handlers) {
  for (handler in handlers) {
    res <- handler(res, req)
  }
  res
}

# Tiny client-side bootstrap injected at the top of <head>. `%s` is the mount
# path. It registers the "redirect" custom message handler backing
# `server_redirect()` (this replaces the old inst/redirect.js), prefixing
# internal targets with the mount so a redirect to "/page2" works under a
# proxy, and dropping any target that is neither a path nor an http(s) url, or
# that carries whitespace or a control character -- a browser strips those out
# of a url, which would turn "java\nscript:" back into a scheme it executes.
#
# It used to also promote the page's <base> to an absolute url, on the premise
# that shiny-server-client computed the websocket url from it. That premise is
# wrong: shiny builds the websocket url from `window.location.pathname`, and on
# Posit Connect sockjs does the same, carrying the worker id in a `w=` segment.
# Checked against a real Connect deployment: with the whole script stripped
# from the response, a deep page kept the same websocket url, the same rendered
# output and no failed request. Connect ships its own <base> script, and
# brochure already rewrites resource urls absolute server-side.
brochure_client_js <- '(function(){var mount="%s";function reg(){if(window.Shiny&&Shiny.addCustomMessageHandler){Shiny.addCustomMessageHandler("redirect",function(to){if(typeof to!=="string"||!to||/[\\s\\u0000-\\u001f\\u007f]/.test(to)||/^\\/\\//.test(to))return;var sch=to.match(/^[a-zA-Z][a-zA-Z0-9+.-]*:/);if(sch&&!/^https?:$/i.test(sch[0]))return;if(!sch&&to.charAt(0)==="/"){to=mount+to;}window.location.href=to;});}}if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",reg);}else{reg();}})();/*__brochure_client__*/'
#' Create a brochureApp
#'
#' This function is to be used in place of `shinyApp()`. It takes a series of
#' `page()`s, each with its own url, UI and server function, and serves them
#' from a single Shiny application.
#'
#' @inheritParams shiny::shinyApp
#' @param ... The `page()`s and `redirect()`s of the app, plus anything to
#' inject __as is__ into every page: tags, tag lists, html dependencies and
#' strings. That is how you add something to all your pages at once, a
#' `<script>` or the resources of a `{golem}` app for example. Note that a
#' string is injected too, so a stray value ends up rendered on every page.
#' Anything else is an error naming the element it cannot use. A bare list is
#' spliced, so `brochureApp(list(page_1(), page_2()))` builds two pages rather
#' than injecting the list into each of them.
#' @param wrapped A UI function wrapping the Brochure UI.
#' Default is `shiny::tagList`.
#' @param basepath The path your app is served under by a reverse proxy. It is
#' removed from the incoming url, so that what is left matches the href of your
#' `page()`, and it is prepended to the urls the app emits. For example, if your
#' app is served at `http://connect.thinkr.fr/brochure/` and your page is named
#' `page1`, use `basepath = "brochure"`.
#' @param req_handlers a list of functions that can manipulate the `req` object.
#' These functions should take `req` as a parameters, and return the `req` object
#' (potentially modified), or an object of class httpResponse. If any of the
#' req_handlers return an httpResponse, this response will be sent to the browser
#' immediately, stopping any other code.
#' @param res_handlers A list of functions that can manipulate the httpResponse
#' object before it is send to the browser. Each function must take a `res` and
#' `req` parameter.
#' @param content_404 The content served when no `page()` matches the url.
#'
#' @details
#' Behind a reverse proxy, `basepath` tells the app where it is mounted: it is
#' removed from the incoming path, and prepended to the urls the app emits.
#' On Posit Connect the mount is picked up on its own, from the
#' `RStudio-Connect-App-Base-URL` header, and `basepath` is not needed. That
#' header is not part of any published contract, so set `basepath` if you want
#' the behaviour pinned. Brochure also injects a small script registering the
#' handler `server_redirect()` talks to, which prefixes internal targets with
#' the mount.
#'
#' @importFrom shiny shinyApp
#' @importFrom rlang as_function
#' @importFrom routr RouteStack
#'
#' @return A shiny.appobj
#' @seealso [page()] to declare a page, [redirect()] to answer an url with a
#' redirection, and `vignette("deployment")` to serve the app under a prefix.
#' @export
#'
#' @examples
#' library(shiny)
#'
#' app <- brochureApp(
#'   page(
#'     href = "/",
#'     ui = tagList(h1("Home")),
#'     server = function(input, output, session) {}
#'   ),
#'   page(
#'     href = "/contact",
#'     ui = tagList(h1("Contact"))
#'   ),
#'   redirect(from = "/index.html", to = "/")
#' )
#'
#' # Then run it as you would any Shiny app:
#' if (interactive()) {
#'   shiny::runApp(app)
#' }
brochureApp <- function(
  ...,
  onStart = NULL,
  options = list(),
  enableBookmarking = NULL,
  content_404 = "Not found",
  basepath = "",
  req_handlers = list(),
  res_handlers = list(),
  wrapped = shiny::tagList
) {
  brochure_routes <- RouteStack$new()
  basepath <- normalize_basepath(basepath)
  # Kept as locals: the httpHandler closure below is the only reader, so two
  # apps running in the same process never see each other's handlers.
  req_handlers <- lapply(req_handlers, as_function)
  res_handlers <- lapply(res_handlers, as_function)
  # Extracting the dots
  content <- check_content(splice_lists(list(...)))

  # Separate the extra content from the pages
  # This allows to add extra deps
  are_pages <- extract(
    content,
    "brochure_page"
  )

  # Which one are page
  pages <- content[are_pages]

  extra <- content[!are_pages]
  are_redirect <- extract(
    extra,
    "redirect"
  )
  redirect <- extra[are_redirect]
  # Non-redirect extras (deps, scripts, golem resources, ...) are injected into
  # every page on top of the page() content, as documented.
  extra_content <- extra[!are_redirect]

  purrr::iwalk(
    pages,
    function(page, index) {
      route <- routr::Route$new(
        ignore_trailing_slash = TRUE
      )
      route$add_handler(
        tolower(
          page$method
        ),
        page$href,
        function(
          request,
          response,
          keys,
          ...
        ) {
          list(
            ui = page$ui,
            server = page$server,
            keys = keys,
            req_handlers = page$req_handlers,
            res_handlers = page$res_handlers
          )
        }
      )
      brochure_routes$add_route(
        route,
        sprintf(
          "page-%s",
          as.character(index)
        )
      )
    }
  )

  purrr::iwalk(
    redirect,
    function(page, index) {
      route <- routr::Route$new(
        ignore_trailing_slash = TRUE
      )
      route$add_handler(
        tolower(
          page$method
        ),
        page$from,
        function(
          request,
          response,
          keys,
          ...
        ) {
          list(
            redirect = httpResponse(
              status = page$code,
              headers = list(
                Location = page$to
              )
            )
          )
        }
      )

      brochure_routes$add_route(
        route,
        sprintf(
          "redirect-%s",
          as.character(index)
        )
      )
    }
  )

  ui <- function(
    request
  ) {
    matched <- brochure_routes$dispatch_to_first_match(request)
    # Stored on the request so that `get_keys(request)` can read them back.
    request$BROCHURE_KEYS <- matched$keys
    ui <- matched$ui

    if (is.function(ui)) {
      ui <- ui(request)
    }
    # Wrap with the user's `wrapped` and inject the extra content (deps, etc.)
    # on top of the page UI.
    wrapped(
      do.call(
        shiny::tagList,
        c(extra_content, list(ui))
      )
    )
  }
  server = function(
    input,
    output,
    session
  ) {
    # Resolve the page from the session's own handshake request, so that
    # concurrent sessions on different pages never see each other's server.
    matched <- brochure_routes$dispatch_to_first_match(
      req_with_path(
        session$request,
        strip_basepath(
          page_path(session$request$PATH_INFO),
          basepath
        )
      )
    )
    session$request$BROCHURE_KEYS <- matched$keys
    if (is.function(matched$server)) {
      matched$server(
        input,
        output,
        session
      )
    }
  }
  res <- shinyApp(
    ui = ui,
    server = server,
    onStart = onStart,
    options = options,
    uiPattern = ".*",
    enableBookmarking = enableBookmarking
  )

  # We're keeping the old `httpHandler`
  old_httpHandler <- res$httpHandler

  res$httpHandler <- function(req) {
    req <- run_req_handlers(req, req_handlers)
    if (inherits(req, "httpResponse")) {
      return(req)
    }
    # Stripped in place, so the `ui()` called further down by the Shiny handler
    # dispatches on the same path we do.
    req$PATH_INFO <- strip_basepath(req$PATH_INFO, basepath)
    dispatched <- brochure_routes$dispatch_to_first_match(req)
    if (is.null(dispatched)) {
      return(make_404(content_404))
    }
    if (!is.null(dispatched$redirect)) {
      return(dispatched$redirect)
    }
    req <- run_req_handlers(req, dispatched$req_handlers)
    if (inherits(req, "httpResponse")) {
      return(req)
    }
    res <- old_httpHandler(req)
    if (is.null(res)) {
      return(res)
    }
    # App level res handlers first, then the ones of the matched page.
    res <- run_res_handlers(res, req, res_handlers)
    res <- run_res_handlers(res, req, dispatched$res_handlers)
    # Make the page work under a reverse-proxy mount. We rewrite resource URLs
    # and internal links to be absolute to the mount (immune to the browser
    # preload scanner, unlike a client-side <base> swap), and inject a tiny
    # script that fixes the <base> for the Shiny websocket only.
    mount <- get_mount(req, basepath)
    if (
      !is.null(res$content) &&
        !grepl("__brochure_client__", res$content, fixed = TRUE)
    ) {
      if (nzchar(mount)) {
        # Internal absolute links: <a href="/x"> -> <a href="/<mount>/x">
        res$content <- gsub(
          '(<a\\b[^>]*?\\shref=")/(?!/)',
          paste0("\\1", mount, "/"),
          res$content,
          perl = TRUE
        )
      }
      # Relative resource URLs (src/href="foo") -> "/<mount>/foo". Always
      # needed, not only under a mount: on a nested page such as "/who/colin"
      # they would otherwise resolve against "/who/" and 404.
      res$content <- gsub(
        '\\b(src|href)="(?![a-zA-Z][a-zA-Z0-9+.-]*:|//|/|#|\\?)',
        paste0("\\1=\"", mount, "/"),
        res$content,
        perl = TRUE
      )
      m <- regexpr("<head>", res$content, ignore.case = TRUE)
      if (m > 0) {
        at <- m + attr(m, "match.length")
        scripttag <- paste0(
          "<script>",
          sprintf(brochure_client_js, mount),
          "</script>"
        )
        res$content <- paste0(
          substr(res$content, 1, at - 1),
          scripttag,
          substring(res$content, at)
        )
      }
    }
    return(res)
  }
  return(res)
}
