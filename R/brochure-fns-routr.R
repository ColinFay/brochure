#' A Brochure Page
#'
#' @param href The endpoint to serve the UI on
#' @param method The HTTP method the page answers to. Defaults to `"GET"`.
#' @inheritParams brochureApp
#' @inheritParams shiny::shinyApp
#'
#' @return A list
#' @export
#'
#' @importFrom shiny tagList
#'
#' @examples
#' library(shiny)
#' page(
#'   href = "/page2",
#'   ui = tagList(
#'     h1("This is my second page"),
#'     plotOutput("plotb")
#'   )
#' )
page <- function(
  href,
  ui = tagList(),
  server = function(input, output, session) {},
  method = "GET",
  req_handlers = list(),
  res_handlers = list()
) {
  # Page are href + ui
  res <- list(
    href = href,
    ui = ui,
    server = server,
    method = tolower(
      method
    ),
    # Carried with the page, so the dispatch can run them for the matched route.
    req_handlers = lapply(req_handlers, as_function),
    res_handlers = lapply(res_handlers, as_function)
  )
  with_class(
    res,
    "brochure_page"
  )
}

#' Redirection
#'
#' @param from redirect from
#' @param to redirect to
#' @param code redirectin http code (one of `c(301:308, 310)`)
#' @param method The HTTP method the redirection answers to.
#' Defaults to `"GET"`.
#'
#' @return A redirection
#' @export
redirect <- function(
  from,
  to,
  code = 301,
  method = "GET"
) {
  # We need the redirect to be a specific HTTP code
  check_redirect_code(code)

  with_class(
    list(
      from = from,
      to = to,
      code = code,
      method = method
    ),
    "redirect"
  )
}
