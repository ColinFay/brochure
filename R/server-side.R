# The target ends up in `window.location.href`, so a "javascript:" or "data:"
# URL would execute in the page, and a "//host" one would silently leave the
# app. Paths and http(s) URLs only. The browser handler applies the same rule,
# since a custom message can also be sent from elsewhere.
check_redirect_to <- function(to) {
  has_scheme <- grepl("^[a-zA-Z][a-zA-Z0-9+.-]*:", to)
  attempt::stop_if_not(
    length(to) == 1 &&
      !grepl("^//", to) &&
      (!has_scheme || grepl("^https?:", to, ignore.case = TRUE)),
    isTRUE,
    "`to` must be a path or an http(s) URL."
  )
  to
}

#' Do a server side redirection
#'
#' @param to the destination of the redirection: a path (`"/page2"`) or an
#' `http(s)` URL. Other schemes are rejected.
#' @param session shiny session object, default is `shiny::getDefaultReactiveDomain()`
#'
#' @return Used for side effect
#' @seealso [redirect()] to answer an url with an HTTP redirection instead.
#' @export
#'
#' @examples
#' library(shiny)
#'
#' # `server_redirect()` is called from a page server, so it needs a session:
#' page(
#'   href = "/login",
#'   ui = tagList(actionButton("go", "Take me home")),
#'   server = function(input, output, session) {
#'     observeEvent(input$go, {
#'       server_redirect("/")
#'     })
#'   }
#' )
server_redirect <- function(
  to,
  session = shiny::getDefaultReactiveDomain()
) {
  session$sendCustomMessage(
    "redirect",
    check_redirect_to(to)
  )
}
