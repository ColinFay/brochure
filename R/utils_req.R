#' @importFrom shiny httpResponse
make_404 <- function(content_404) {
  httpResponse(
    status = 404,
    content = as.character(
      content_404
    )
  )
}
