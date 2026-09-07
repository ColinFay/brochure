#' Get the keys of a parameterised page
#'
#' A page declared with a parameterised `href` (e.g. `"/who/:id"`) exposes the
#' values matched in the URL through `get_keys()`. Call it with no argument
#' inside a page `server`, and pass it the `request` inside a page `ui`.
#'
#' @param x A shiny session, or the `request` object a page `ui` receives.
#' Defaults to the session the code is running in.
#'
#' @return A named list of the values matched in the page `href`, or `NULL`
#' outside of a brochure page.
#' @export
#'
#' @examples
#' library(shiny)
#' page(
#'   href = "/who/:id",
#'   ui = function(request) {
#'     h1(get_keys(request)$id)
#'   },
#'   server = function(input, output, session) {
#'     print(get_keys())
#'   }
#' )
get_keys <- function(x = shiny::getDefaultReactiveDomain()) {
  # A session carries the request it was opened with; a `ui` is handed the
  # request itself. Both hold the keys the dispatch matched.
  req <- x$request
  if (is.null(req)) {
    req <- x
  }
  req$BROCHURE_KEYS
}
