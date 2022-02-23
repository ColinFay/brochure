#' Do a server side redirection
#'
#' @param to the destination of the redirection
#' @param session shiny session object, default is `shiny::getDefaultReactiveDomain()`
#'
#' @export
server_redirect <- function(
  to,
  session = shiny::getDefaultReactiveDomain()
) {
  session$sendCustomMessage(
    "redirect",
    to
  )
}
