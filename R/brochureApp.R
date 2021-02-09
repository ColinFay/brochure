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
    uiPattern = ".*", # This is where the magic happens
    enableBookmarking = enableBookmarking
  )

  # We're keeping the old `httpHandler`
  old_httpHandler <- res$httpHandler

  res$httpHandler <- function(req){

    # Handling the app level middleware
    app_middleware <- get_middleware_app()

    if (length( app_middleware )){
      for (i in app_middleware ){
        req  <- i(req)
        # If any middleware return an 'httpResponse', return it directly without doing
        # anything else
        if ( "httpResponse" %in% class(req) ){
          return(req)
        }
      }
    }

    # Handle redirect
    if (req$PATH_INFO %in% ...multipage_opts$redirect$from){
      return(
        make_redirect(req$PATH_INFO)
      )
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
      return( make_404(content_404))
    }

    # Setting the path info for reuse in brochure()
    ...multipage_opts$path <- req$PATH_INFO

    #browser()
    # Handling the page level middleware
    page_middlewares <- get_middleware_page(
      gsub(".+/$", "", req$PATH_INFO)
    )
    if ( length( page_middlewares ) ){
      for (i in page_middlewares){
        req <- i(req)
        if ( "httpResponse" %in% class(req) ){
          return(req)
        }
      }
    }

    http_resp <- old_httpHandler(req)

    #browser()

    app_finalizers <- get_finalizer_app()

    if (length(app_finalizers)){
      for (i in app_finalizers){
        http_resp <- i(http_resp, req)
      }
    }

    page_finalizers <- get_finalizer_page(req$PATH_INFO)

    if (length(page_finalizers)){
      for (i in page_finalizers){
        http_resp <- i(http_resp, req)
      }
    }

    if (with_cookie){
      # browser()
      current_cookie <- parse_cookie(
        req$HTTP_COOKIE
      )["brochure_session"]
      if (
        is.na(current_cookie) |
        ! cookie_storage()$is_valid(
          current_cookie
        )
      ){
        http_resp$headers <- list(
          "Set-Cookie" = sprintf(
            "brochure_session=%s; HttpOnly; Expires=Wed, 21 Oct 2050 07:28:00 GMT;Path=/",
            cookie_storage()$add_cookie()
          )
        )
      }
    }

    http_resp
  }
  res
}

