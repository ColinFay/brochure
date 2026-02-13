globals <- fastmap::fastmap()
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
    # We add the resource path if needed
    # So that Connect and all can find the
    # resources
    if (
      brochure_routing[[
        brochure_id
      ]]$static_path !=
        "/"
    ) {
      paths <- shinyOptions()$server$getStaticPaths()
      for (path in paths) {
        shiny::addResourcePath(
          brochure_routing[[
            brochure_id
          ]]$static_path,
          shinyOptions()$server$getStaticPaths()[[path]]path
        )
      }
    }

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
    if (!grepl("<base href", res$content)) {
      res$content <- sub(
        "<head>",
        "<head><base href=\'/'>",
        res$content,
        ignore.case = TRUE
      )
    }
    return(res)
  }
  return(res)
}
