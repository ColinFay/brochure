#' Create a brochureApp
#'
#' This function  is to be used in place of
#' `shinyApp()`.
#'
#' @inheritParams shiny::shinyApp
#' @param ... a list of `Page()`
#' @param wrapped A UI function wrapping the Brochure UI.
#' Default is `shiny::fluidPage`.
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
  wrapped = shiny::fluidPage
) {

  # Saving the brochure
  brochure(
    ...,
    basepath = "",
    req_handlers = req_handlers,
    res_handlers = res_handlers,
    wrapped = wrapped
  )

  # We add this enabled, just to be sure
  # `brochure_enable` is called inside a
  # `brochureApp`
  ...multipage_opts$enabled <- TRUE

  # We build the shinyApp object here
  res <- shinyApp(
    ui = function(request) {

      # Extract the correct UI, wrap it
      # and add the redirect from brochure
      ui <- ...multipage[[
      rm_backslash(request$PATH_INFO)
      ]]$ui

      if (is.function(ui)) {
        ui <- ui(request)
      }

      ...multipage_opts$wrapped(
        tagList(
          shiny::includeScript(
            system.file(
              "redirect.js",
              package = "brochure"
            )
          ),
          ...multipage_opts$extra,
          ui
        )
      )
    },
    server = function(input, output, session) {
      # Same logic as the UI, we look for the correct
      # server function
      path <- rm_backslash(
        gsub(
          "websocket/",
          "",
          session$request$PATH_INFO
        )
      )
      ...multipage[[
      path
      ]]$server(input, output, session)
    },
    onStart = onStart,
    options = options,
    uiPattern = ".*", # This is where the magic happens
    enableBookmarking = enableBookmarking
  )

  # We're keeping the old `httpHandler`
  old_httpHandler <- res$httpHandler

  res$httpHandler <- function(req) {

    # Handling the app level req_handlers
    app_req_handlers <- get_req_handlers_app()

    if (length(app_req_handlers)) {
      for (i in app_req_handlers) {
        req <- i(req)
        # If any req_handlers return an 'httpResponse', return it directly without doing
        # anything else.
        if ("httpResponse" %in% class(req)) {
          return(res)
        }
      }
    }


    req$PATH_INFO <- rm_backslash(req$PATH_INFO)

    # Handle redirect
    if (req$PATH_INFO %in% ...multipage_opts$redirect$from) {
      return(
        make_redirect(req$PATH_INFO)
      )
    }

    # Returning a 404 if the page doesn't exist
    if (!req$PATH_INFO %in% names(...multipage)) {
      return(make_404(content_404))
    }

    # Setting the path info for reuse in brochure()
    ...multipage_opts$path <- req$PATH_INFO

    # Handling the page level req_handlers
    page_req_handlers <- get_req_handlers_page(
      gsub(".+/$", "", req$PATH_INFO)
    )

    if (length(page_req_handlers)) {
      for (i in page_req_handlers) {
        req <- i(req)
        if ("httpResponse" %in% class(req)) {
          return(req)
        }
      }
    }

    res <- old_httpHandler(req)

    # Res handling
    res <- handle_res_with_handlers(res, req)
    return(res)
  }
  return(res)
}
