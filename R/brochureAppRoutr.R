globals <- fastmap::fastmap()

# Determine the external mount path of the app (the part the reverse proxy
# serves it under, e.g. "/brochuresubpage"). Posit Connect forwards it in the
# `RSTUDIO_CONNECT_APP_BASE_URL` header. Falls back to the `basepath` argument,
# then to "" (app served at the domain root, e.g. local dev).
get_mount <- function(req, basepath = "") {
  base_url <- req[["HTTP_RSTUDIO_CONNECT_APP_BASE_URL"]]
  if (!is.null(base_url) && nzchar(base_url)) {
    path <- sub("^[a-zA-Z][a-zA-Z0-9+.-]*://[^/]+", "", base_url)
    path <- sub("/+$", "", path)
    if (nzchar(path)) {
      return(path)
    }
  }
  bp <- gsub("^/+|/+$", "", basepath)
  if (nzchar(bp)) {
    return(paste0("/", bp))
  }
  ""
}

# This has been vibe coded

# Tiny client-side bootstrap injected at the top of <head>. `%s` is the
# server-known mount path. It does two things:
#
# 1. WEBSOCKET base. Resources and links are made absolute server-side (immune
#    to the browser preload scanner), but the websocket URL is computed at
#    runtime by shiny-server-client against the page's <base>. Under a
#    worker-tokenized proxy (Connect) that base is RELATIVE (`_w_<token>/`) and
#    resolves wrong on deep pages, so we promote it to an ABSOLUTE base
#    (origin + mount + token), preserving the worker token. No-op when there is
#    no worker token (e.g. local dev).
# 2. server_redirect(). Registers the "redirect" custom message handler (this
#    replaces the old inst/redirect.js), mount-prefixing internal targets so a
#    redirect to "/page2" works under a proxy mount.
brochure_client_js <- '(function(){var mount="%s";var bs=document.getElementsByTagName("base");var token="";for(var i=0;i<bs.length;i++){var h=bs[i].getAttribute("href")||"";var m=h.match(/_w_[^\\/]+/);if(m){token=m[0]+"/";break;}}if(token){for(var j=bs.length-1;j>=0;j--){bs[j].parentNode.removeChild(bs[j]);}var b=document.createElement("base");b.setAttribute("href",window.location.origin+mount+"/"+token);var head=document.head||document.getElementsByTagName("head")[0];head.insertBefore(b,head.firstChild);}function reg(){if(window.Shiny&&Shiny.addCustomMessageHandler){Shiny.addCustomMessageHandler("redirect",function(to){if(to&&to.charAt(0)==="/"&&to.charAt(1)!=="/"){to=mount+to;}window.location.href=to;});}}if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",reg);}else{reg();}})();/*__brochure_client__*/'
#' Create a brochureApp
#'
#' This function  is to be used in place of
#' `shinyApp()`.
#'
#' @inheritParams shiny::shinyApp
#' @param ... a list of elements to inject in the brochureApp.
#' __IMPORTANT NOTE__ all elements which are not of class `"brochure_*"`
#' will be injected __as is__ in the page. In other word, if you use a function
#' that return a string, the string will be added as is to the pages.
#' The only elements that should be injected on top of `page()`s are HTML elements
#' and/or `tagList/tags` that are invisible on screen (for example a `<script></script>`).
#' @param wrapped A UI function wrapping the Brochure UI.
#' Default is `shiny::tagList`.
#' @param basepath The base path of your app. This pattern will be removed from the
#' url, so that it matches the href of your `page()`. For example, it you have
#' an app at `http://connect.thinkr.fr/brochure/`, and your page is names `page1`,
#' use `basepath = "brochure"`
#' @param req_handlers a list of functions that can manipulate the `req` object.
#' These functions should take `req` as a parameters, and return the `req` object
#' (potentially modified), or an object of class httpResponse. If any of the
#' req_handlers return an httpResponse, this response will be sent to the browser
#' immeditately, stopping any other code.
#' @param res_handlers A list of functions that can manipulate the httpResponse
#' object before it is send to the browser. Each function must take a `res` and
#' `req` parameter.
#' @param content_404 The content to dislay when a 404 is sent
#' @importFrom shiny shinyApp
#'
#' @return A shiny.appobj
#' @export
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
  brochure_routing <- new.env()
  brochure_routes <- RouteStack$new()
  brochure_id <- uuid::UUIDgenerate()
  globals$set(
    "req_handlers",
    req_handlers
  )
  globals$set(
    "res_handlers",
    res_handlers
  )
  # Extracting the dots
  content <- list(...)

  # Separate the extra content from the pages
  # This allows to add extra deps
  are_pages <- extract(
    content,
    "brochure_page"
  )

  # Which one are page
  pages <- content[are_pages]

  extra <- content[!are_pages]
  redirect <- extra[
    extract(
      extra,
      "redirect"
    )
  ]

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
            redirect = NULL,
            static_path = page$href
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

  makeActiveBinding(
    "keys",
    function() {
      brochure_routing[[
        brochure_id
      ]]$keys
    },
    env = sys.frame()
  )

  ui <- function(
    request
  ) {
    ui <- brochure_routing[[
      brochure_id
    ]]$ui

    if (is.function(ui)) {
      ui <- ui(request)
    }
    ui
  }
  server = function(
    input,
    output,
    session
  ) {
    brochure_routing[[
      brochure_id
    ]]$server(
      input,
      output,
      session
    )
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
    if (length(globals$get("req_handlers")) > 0) {
      for (handler in globals$get("req_handlers")) {
        req <- handler(req)
        if (inherits(req, "httpResponse")) {
          return(req)
        }
      }
    }
    dispatched <- brochure_routes$dispatch_to_first_match(req)
    if (is.list(dispatched) && !is.null(dispatched$redirect)) {
      return(dispatched$redirect)
    }
    # Only update the stored page state when the request actually matched a
    # brochure page. Stray requests (resources, favicon, sockjs, ...) that fall
    # through here must NOT clobber the current page's ui/server with NULL, or
    # the next Shiny session would call a non-function server.
    if (
      is.list(dispatched) &&
        (!is.null(dispatched$ui) ||
          !is.null(dispatched$server) ||
          !is.null(dispatched$static_path))
    ) {
      brochure_routing[[brochure_id]]$ui <- dispatched$ui
      brochure_routing[[brochure_id]]$server <- dispatched$server
      brochure_routing[[brochure_id]]$keys <- dispatched$keys
      brochure_routing[[brochure_id]]$static_path <- dispatched$static_path
    }
    res <- old_httpHandler(req)
    if (is.null(res)) {
      return(res)
    }
    if (length(globals$get("res_handlers")) > 0) {
      for (handler in globals$get("res_handlers")) {
        res <- handler(res, req)
      }
    }
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
        # Relative resource URLs (src/href="foo") -> "/<mount>/foo"
        res$content <- gsub(
          '\\b(src|href)="(?![a-zA-Z][a-zA-Z0-9+.-]*:|//|/|#|\\?)',
          paste0("\\1=\"", mount, "/"),
          res$content,
          perl = TRUE
        )
      }
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
