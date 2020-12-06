#' Constrain a code on a Page
#'
#' @param page name of the page
#' @param expr expression to be run on the given page
#' @param session a Shiny session object
#'
#' @return Used for side effect
#' @export
onPage <- function(
  page,
  expr,
  session = getDefaultReactiveDomain()
){

  observe({
    url_hash <- gsub("/", "", session$clientData$url_pathname)
    page <- gsub("/", "", page)
    if (url_hash == "page2") force(expr)
  })

}
