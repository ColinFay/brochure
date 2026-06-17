# Storing the content of the multipage
...multipage <- new.env()
# Env to store the options
...multipage_opts <- new.env()


#' A Brochure Page
#'
#' @param href The endpoint to serve the UI on
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
  # href <- rm_backslash(href)
  # Page are href + ui
  res <- list(
    href = href,
    ui = ui,
    server = server,
    method = tolower(
      method
    )
  )
  # Adding the page level req_handlerss
  add_req_handlers_page(
    href,
    req_handlers
  )
  add_res_handlers_page(
    href,
    res_handlers
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
