#' A Brochure Page
#'
#' A page is an url, a UI and a server function. Opening it starts a Shiny
#' session of its own, separate from any other page of the app.
#'
#' @param href The endpoint to serve the UI on. It can carry parameters, as in
#' `"/who/:id"`, which are read back with [get_keys()]. See details.
#' @param method The HTTP method the page answers to. Defaults to `"GET"`.
#' @inheritParams brochureApp
#' @inheritParams shiny::shinyApp
#'
#' @details
#' Requests are matched against hrefs by the \pkg{routr} package, so an href is
#' written the way routr writes a path:
#'
#' - `"/contact"` matches that path and nothing else.
#' - `":name"` matches exactly one segment and captures it, so `"/who/:id"`
#'   matches `/who/colin` but neither `/who` nor `/who/colin/edit`. Use several
#'   of them if you need to: `"/pair/:a/:b"`.
#' - `"*"` matches whatever is left, so `"/files/*"` matches `/files/a/b/c`.
#'   The captured value is named `*1`.
#'
#' A trailing slash never matters: `/contact` and `/contact/` are the same page.
#'
#' Pages are tried in the order you passed them to [brochureApp()], and the
#' first match wins. That matters when two hrefs can match the same url:
#' declared as `page("/who/me")` then `page("/who/:id")`, a request for
#' `/who/me` gets the first; declared the other way round, the parameterised
#' page catches it and the static one is never reached. Put the specific ones
#' first.
#'
#' See the \pkg{routr} documentation at
#' <https://routr.data-imaginist.com/> for the full path syntax.
#'
#' @return A `brochure_page` object, to be passed to [brochureApp()].
#' @seealso [get_keys()] to read the parameters of an href, and
#' `vignette("handlers")` for `req_handlers` and `res_handlers`.
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
#' Answers an url with an HTTP redirection, before any Shiny code runs. To
#' redirect from inside a page server instead, see [server_redirect()].
#'
#' @param from the url to redirect from
#' @param to the url to redirect to
#' @param code redirecting http code (one of `c(301:308, 310)`)
#' @param method The HTTP method the redirection answers to.
#' Defaults to `"GET"`.
#'
#' @return A `redirect` object, to be passed to [brochureApp()].
#' @seealso [server_redirect()] to redirect from inside a page server.
#' @export
#'
#' @examples
#' redirect(
#'   from = "/index.html",
#'   to = "/"
#' )
#'
#' # Anything but a temporary move deserves a code of its own
#' redirect(
#'   from = "/old",
#'   to = "/new",
#'   code = 302
#' )
redirect <- function(
  from,
  to,
  code = 301,
  method = "GET"
) {
  # We need the redirect to be a specific HTTP code
  check_redirect_code(code)
  # `to` is written straight into a Location header, so it is held to the same
  # rule as `server_redirect()`: a CRLF here would append a header of its own.
  check_redirect_to(to)

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
