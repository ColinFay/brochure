globals <- fastmap::fastmap()

# Client-side base/URL fixer injected at the top of <head>.
#
# Reverse proxies like Posit Connect inject a RELATIVE <base href="_w_<token>/">
# that the browser resolves against the (possibly deep) document URL. On non-root
# pages (e.g. /page1/sous-page/) this resolves resources and links to the wrong
# place -> 404. This script promotes that base to an ABSOLUTE, depth-independent
# one (origin + mount + token): it computes the mount from location.pathname by
# stripping the current page's depth (`%d`, injected server-side), preserves the
# worker token (so the Shiny websocket / reactivity keeps working), then rewrites
# internal absolute links (<a href="/...">) to include the mount path.
base_fixer_js <- '(function(){var d=%d;var loc=window.location;var segs=loc.pathname.replace(/\\/+$/,"").split("/");var mount=segs.slice(0,Math.max(1,segs.length-d)).join("/");var token="";var bases=document.getElementsByTagName("base");for(var i=0;i<bases.length;i++){var h=bases[i].getAttribute("href")||"";var mm=h.match(/_w_[^\\/]+/);if(mm){token=mm[0]+"/";break;}}var ab=loc.origin+mount+"/"+token;var head=document.head||document.getElementsByTagName("head")[0];for(var j=bases.length-1;j>=0;j--){bases[j].parentNode.removeChild(bases[j]);}var b=document.createElement("base");b.setAttribute("href",ab);head.insertBefore(b,head.firstChild);function fixLinks(){var as=document.getElementsByTagName("a");for(var k=0;k<as.length;k++){var href=as[k].getAttribute("href");if(href&&href.charAt(0)==="/"&&href.charAt(1)!=="/"){as[k].setAttribute("href",(mount==="/"?"":mount)+href);}}}if(document.readyState==="loading"){document.addEventListener("DOMContentLoaded",fixLinks);}else{fixLinks();}})();/*__brochure_base_fixer__*/'
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
    ## --- DÉSACTIVÉ pour la Phase 0 (sous-page / Connect) ------------
    ## Tentative "alias serveur" (famille B) : ré-enregistrer les
    ## static paths de Shiny sous le préfixe de la page courante.
    ## Cassé en l'état : (1) erreur de syntaxe `[[path]]path`,
    ## (2) addResourcePath() refuse un préfixe contenant des "/"
    ## (or static_path vaut p.ex. "/page1/sous-page"), donc plantait
    ## sur toute page non-racine. À redessiner en Phase 1 selon les logs.
    ##
    ## if (brochure_routing[[brochure_id]]$static_path != "/") {
    ##   paths <- shinyOptions()$server$getStaticPaths()
    ##   for (path in paths) {
    ##     shiny::addResourcePath(
    ##       brochure_routing[[brochure_id]]$static_path,
    ##       path$path
    ##     )
    ##   }
    ## }
    ## --- FIN DÉSACTIVÉ ----------------------------------------------

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
    ## --- TEMP DEBUG (Phase 0 sous-page / Connect) -------------------
    ## Activer avec options("brochure.debug" = TRUE).
    ## A RETIRER une fois le diagnostic Connect terminé.
    if (isTRUE(getOption("brochure.debug", FALSE))) {
      message("== brochure.debug == REQUEST PATH_INFO: ", req$PATH_INFO)
      for (k in sort(ls(req))) {
        if (grepl(
          "^(HTTP_|PATH_INFO$|SCRIPT_NAME$|QUERY_STRING$|SERVER_NAME$|SERVER_PORT$)",
          k
        )) {
          v <- tryCatch(
            paste(as.character(req[[k]]), collapse = " "),
            error = function(e) "<unprintable>"
          )
          message("== brochure.debug ==   ", k, ": ", v)
        }
      }
    }
    ## --- END TEMP DEBUG ---------------------------------------------
    if (length(globals$get("req_handlers")) > 0) {
      for (handler in globals$get("req_handlers")) {
        req <- handler(req)
        if (inherits(req, "httpResponse")) {
          return(req)
        }
      }
    }
    dispatched <- brochure_routes$dispatch_to_first_match(req)
    brochure_routing[[
      brochure_id
    ]]$ui <- dispatched$ui
    brochure_routing[[
      brochure_id
    ]]$server <- dispatched$server
    brochure_routing[[
      brochure_id
    ]]$keys <- dispatched$keys
    if (
      !is.null(
        dispatched$redirect
      )
    ) {
      return(
        dispatched$redirect
      )
    }
    brochure_routing[[
      brochure_id
    ]]$static_path <- dispatched$static_path
    res <- old_httpHandler(req)
    if (is.null(res)) {
      return(res)
    }
    if (length(globals$get("res_handlers")) > 0) {
      for (handler in globals$get("res_handlers")) {
        res <- handler(res)
        if (inherits(req, "httpResponse")) {
          return(req)
        }
      }
    }
    # Inject the brochure base/URL fixer right after <head>, so it runs before
    # the page resources (and after Connect's injected base) are parsed.
    sp <- brochure_routing[[
      brochure_id
    ]]$static_path
    if (is.null(sp)) {
      sp <- "/"
    }
    if (
      !is.null(res$content) &&
        !grepl("__brochure_base_fixer__", res$content, fixed = TRUE)
    ) {
      m <- regexpr("<head>", res$content, ignore.case = TRUE)
      if (m > 0) {
        trimmed <- gsub("^/+|/+$", "", sp)
        depth <- if (identical(trimmed, "")) {
          0L
        } else {
          length(strsplit(trimmed, "/", fixed = TRUE)[[1]])
        }
        at <- m + attr(m, "match.length")
        scripttag <- paste0(
          "<script>",
          sprintf(base_fixer_js, depth),
          "</script>"
        )
        res$content <- paste0(
          substr(res$content, 1, at - 1),
          scripttag,
          substring(res$content, at)
        )
      }
    }
    ## --- TEMP DEBUG (Phase 0 sous-page / Connect) -------------------
    ## A RETIRER une fois le diagnostic Connect terminé.
    if (
      isTRUE(getOption("brochure.debug", FALSE)) &&
        !is.null(res$content)
    ) {
      message(
        "== brochure.debug == RESPONSE static_path: ",
        brochure_routing[[brochure_id]]$static_path
      )
      message(
        "== brochure.debug == RESPONSE has <base>: ",
        grepl("<base", res$content, ignore.case = TRUE)
      )
      head_html <- regmatches(
        res$content,
        regexpr("(?is)<head.*?</head>", res$content, perl = TRUE)
      )
      message(
        "== brochure.debug == RESPONSE <head> (1ers 1500 car.): ",
        substr(paste(head_html, collapse = ""), 1, 1500)
      )
    }
    ## --- END TEMP DEBUG ---------------------------------------------
    return(res)
  }
  return(res)
}
