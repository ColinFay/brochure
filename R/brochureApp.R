#' Create a brochureApp
#'
#' This function  is to be used in place of
#' `shinyApp()`.
#'
#' @inheritParams shiny::shinyApp
#' @param content_404 The content to dislay when a 404 is sent
#' @importFrom shiny shinyApp
#'
#' @return A shiny.appobj
#' @export
brochureApp <- function(
  ui,
  server,
  onStart = NULL,
  options = list(),
  enableBookmarking = NULL,
  content_404 = "Not found"
){
  # We add this enabled, just to be sure
  # `brochure_enable` is called inside a
  # `brochureApp`
  ...multipage_opts$enabled <- TRUE
  # Force UI if it hasn't been evaluated yet
  # So that we are sure `...multipage` are
  # enable
  if (is.function(ui)) ui()
  res <- shinyApp(
    ui = ui,
    server = server,
    onStart = onStart,
    options = options,
    uiPattern = ".*",
    enableBookmarking = enableBookmarking
  )
  old_httpHandler <- res$httpHandler
  res$httpHandler <- function(req){

    # Handle redirect
    if (req$PATH_INFO %in% ...multipage_opts$redirect$from){
      dest <- ...multipage_opts$redirect[
        ...multipage_opts$redirect$from == req$PATH_INFO,
      ]
      httpResponse <- getFromNamespace("httpResponse", "shiny")
      return(httpResponse(
        status = dest$code,
        headers = list(
          Location = dest$to
        )
      ))
    }

    # Returning a 404 if the page doesn't exist
    if (!req$PATH_INFO %in% names(...multipage)){
      httpResponse <- getFromNamespace("httpResponse", "shiny")
      return(httpResponse(
        status = 404,
        content = as.character(content_404)
      ))
    }
    # Setting the path info for reuse in brochure()
    ...multipage_opts$path <- req$PATH_INFO


    # Note to self:
    # req$HTTP_COOKIE
    old_httpHandler(req)
  }
  res
}

