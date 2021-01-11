#' Create a brochureApp
#'
#' This function  is to be used in place of
#' `shinyApp()`.
#'
#' @inheritParams shiny::shinyApp
#' @param content_404 The content to dislay when a 404 is sent
#' @param with_cookie Should the app set session cookies?
#' @param cookie_storage A function returning a list to manage cookies
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
  content_404 = "Not found",
  with_cookie = TRUE,
  # Use a function as cookie storage, this allows to
  # pass your own
  cookie_storage = local_cookie
){
  # We add this enabled, just to be sure
  # `brochure_enable` is called inside a
  # `brochureApp`
  ...multipage_opts$enabled <- TRUE

  # Force UI if it hasn't been evaluated yet
  # So that we are sure `...multipage`  and `...multipage_opts`
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

    httpResponse <- utils::getFromNamespace("httpResponse", "shiny")
    # Redirect to url with backslash.
    # I should probably find a better way to so that
    shiny::updateQueryString(queryString = req$PATH_INFO)
    # if (grepl("/.+/$", req$PATH_INFO)){
    #   shiny::updateQueryString(queryString = req$PATH_INFO)
    #   # return(httpResponse(
    #   #   status = 302,
    #   #   headers = list(
    #   #     Location = gsub("(.+)/", "\\1", )
    #   #   )
    #   # ))
    # }
    # Handle redirect
    if (req$PATH_INFO %in% ...multipage_opts$redirect$from){
      dest <- ...multipage_opts$redirect[
        ...multipage_opts$redirect$from == req$PATH_INFO,
      ]
      return(httpResponse(
        status = dest$code,
        headers = list(
          Location = dest$to
        )
      ))
    }

    # Handle logout form,
    # we want to remove the cookie
    if (req$PATH_INFO %in% ...multipage_opts$logout$from){
      dest <- ...multipage_opts$logout[
        ...multipage_opts$logout$from == req$PATH_INFO,
      ]
      # Remove the cookie from the storage,
      # This will allow to issue a new one when the page reloads
      # as it won't be valid anymore
      cookie_storage()$delete_cookie(
        parse_cookie(req$HTTP_COOKIE)["brochure_session"]
      )
      return(httpResponse(
        status = 302,
        headers = list(
          Location = dest$to
        )
      ))
    }


    # Returning a 404 if the page doesn't exist
    if (!req$PATH_INFO %in% names(...multipage)){
      return(httpResponse(
        status = 404,
        content = as.character(content_404)
      ))
    }
    # Setting the path info for reuse in brochure()
    ...multipage_opts$path <- req$PATH_INFO

    # Note to self:
    # req$HTTP_COOKIE
    # session$request$HTTP_COOKIE
    inter <- old_httpHandler(req)
    if (with_cookie){
      # browser()
      current_cookie <- parse_cookie(req$HTTP_COOKIE)["brochure_session"]
      if (
        is.na(current_cookie) |
        ! cookie_storage()$is_valid(
          current_cookie
        )
      ){
        inter$headers <- list(
          "Set-Cookie" = sprintf(
            "brochure_session=%s; HttpOnly; Expires=Wed, 21 Oct 2050 07:28:00 GMT;Path=/",
            cookie_storage()$add_cookie()
          )
        )
      }
    }

    inter
  }
  res
}

