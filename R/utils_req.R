# Just to be sure we've got the object, as it is only exported
# since 1.6
#' @importFrom shiny httpResponse
make_redirect <- function(PATH_INFO) {
  dest <- ...multipage_opts$redirect[
    ...multipage_opts$redirect$from == PATH_INFO,
  ]
  httpResponse(
    status = dest$code,
    headers = list(
      Location = dest$to
    )
  )
}

make_404 <- function(content_404) {
  httpResponse(
    status = 404,
    content = as.character(
      content_404
    )
  )
}

handle_res_with_handlers <- function(res, req) {
  app_res_handlers <- get_res_handlers_app()

  if (length(app_res_handlers)) {
    for (i in app_res_handlers) {
      res <- i(res, req)
    }
  }

  page_res_handlers <- get_res_handlers_page(
    req$PATH_INFO
  )

  if (
    length(page_res_handlers)
  ) {
    for (i in page_res_handlers) {
      res <- i(res, req)
    }
  }

  res
}
