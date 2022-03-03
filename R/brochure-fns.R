# Storing the content of the multipage
...multipage <- new.env()
# Env to store the options
...multipage_opts <- new.env()

#' @param ... a list of `Page()`
#' @param wrapped A UI function wrapping the Brochure UI.
#' Default is `shiny::fluidPage`.
#' @param basepath The base path of your app. This pattern will be removed from the
#' url, so that it matches the href of your `page()`. For example, it you have
#' an app at `http://connect.thinkr.fr/brochure/`, and your page is names `page1`,
#' use `basepath = "brochure"`
#' @param req_handlers a list of functions that can manipulate the `req` object.
#' These functions should take `req` as a parameters, and return the `req` object
#' (potentially modified), or an object of class httpResponse. If any of the
#' req_handlers return an httpResponse, this response will be sent to the browser
#' immeditately, stopping any other code.
#' @param res_handlers A list of functions that can manipulate the httpResponse
#' object before it is send to the browser. Each function must take a `res` and
#' `req` parameter.
#'
#' @return An HTML UI
#' @noRd
#' @importFrom shiny tagList
brochure <- function(
  ...,
  basepath = "",
  req_handlers = list(),
  res_handlers = list(),
  wrapped = shiny::fluidPage
) {
  # Put the basepath and the req_handlerss
  ...multipage_opts$basepath <- basepath
  ...multipage_opts$req_handlers <- req_handlers
  ...multipage_opts$res_handlers <- res_handlers

  # Extracting the dots
  content <- list(...)

  # Separate the extra content from the pages
  # This allows to add extra deps
  are_pages <- extract(
    content,
    "brochure_page"
  )

  # Which one are page
  pages <- content[are_pages]

  extra <- content[!are_pages]

  # Extract and store the redirects
  are_redirect <- extract(
    extra,
    "redirect"
  )

  # We'll add a dataframe of redirection
  ...multipage_opts$redirect <- build_redirect(
    extra[are_redirect]
  )

  # We don't need the redirect in extra
  # extra <- extra[ !are_redirect ]
  ...multipage_opts$extra <- extra[!are_redirect]
  ...multipage_opts$wrapped <- wrapped

  # Force a `/` page
  all_href <- vapply(
    pages,
    function(x) {
      x$href
    },
    FUN.VALUE = character(1)
  )

  if (!"/" %in% all_href) {
    stop("You must specify a root page (one with `href = '/')`.")
  }

  # Saving all the UIs
  x <- lapply(
    pages,
    function(x, extra = extra) {
      ...multipage[[x$href]]$ui <- x$ui
      ...multipage[[x$href]]$server <- x$server
    }
  )
}

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
  req_handlers = list(),
  res_handlers = list()
) {
  href <- rm_backslash(href)
  # Page are href + ui
  res <- list(
    href = href,
    ui = ui,
    server = server
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
  code = 301
) {

  # We need the redirect to be a specific HTTP code
  check_redirect_code(code)

  res <- list(
    from = from,
    to = to,
    code = code
  )

  with_class(
    res,
    "redirect"
  )
}
