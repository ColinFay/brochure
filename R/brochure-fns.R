# Storing the content of the multipage
...multipage <- new.env()
# Env to store the options
...multipage_opts <- new.env()

#' A Brochure Page
#'
#' @param href The endpoint to serve the UI on
#' @param ui Content served at `/href`
#' @param middleware a list of functions that can manipulate the `req` object.
#' These functions should take `req` as a parameters, and return the `req` object
#' (potentially modified), or an object of class httpResponse. If any of the
#' middleware return an httpResponse, this response will be sent to the browser
#' immeditately, stopping any other code.
#'
#' @return A list
#' @export
#'
#' @importFrom shiny tagList
#'
#' @examples
#' library(shiny)
#' page(
#'  href = "/page2",
#'  ui =  tagList(
#'    h1("This is my second page"),
#'    plotOutput("plotb")
#'  )
#' )
#'
page <- function(
  href,
  ui,
  middleware = list(),
  finalizer = list()
){
  # Page are href + ui
  res <- list(
    href = href,
    ui = tagList(ui)
  )
  # Adding the page level middlewares
  add_middleware_page(href, middleware)
  add_finalizer_page(href, finalizer)
  with_class(res, "brochure_page")
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
){
  # We need the redirect to be a specific HTTP code
  check_redirect_code(code)

  res <- list(
    from = from,
    to = to,
    code = code
  )

  with_class(res, "redirect")
}


#' Remove Current Brochure Cookie
#'
#' This is usually considered as a "log out" mechanism
#'
#' @param href The endpoint of the logout page
#' @param redirect_to The page to redirect to after cookie removal
#'
#' @return Redirection
#' @export
#'
logout <- function(
  href,
  redirect_to
){
  res <- list(from = href, to = redirect_to)
  class(res) <- c("logout", class(res))
  res
}

#' Create the UI for a Brochure
#'
#' @param ... a list of `Page()`
#' @param wrapped A UI function wrapping the Brochure UI.
#' Default is `shiny::fluidPage`.
#' @param basepath The base path of your app. This pattern will be removed from the
#' url, so that it matches the href of your `page()`. For example, it you have
#' an app at `http://connect.thinkr.fr/brochure/`, and your page is names `page1`,
#' use `basepath = "brochure"`
#' @param middleware a list of functions that can manipulate the `req` object.
#' These functions should take `req` as a parameters, and return the `req` object
#' (potentially modified), or an object of class httpResponse. If any of the
#' middleware return an httpResponse, this response will be sent to the browser
#' immeditately, stopping any other code.
#'
#' @return An HTML UI
#' @export
#' @importFrom shiny tagList
brochure <- function(
  ...,
  basepath = "",
  middleware = list(),
  finalizer = list(),
  wrapped = shiny::fluidPage
){
  # Put the basepath and the middlewares
  ...multipage_opts$basepath  <- basepath
  ...multipage_opts$middleware  <- middleware
  ...multipage_opts$finalizer  <- finalizer

  #browser()

  # Extracting the dots
  content <- list(...)

  # Separate the extra content from the pages
  # This allows to add extra deps
  are_pages <- extract(content, "brochure_page")

  # Which one are page
  pages <- content[ are_pages ]

  extra <- content[ !are_pages ]

  # Extract and store the redirects
  are_redirect <- extract(extra, "redirect")

  # We'll add a dataframe of redirection
  ...multipage_opts$redirect <- build_redirect(
    extra[ are_redirect ]
  )

  # We don't need the redirect in extra
  extra <- extra[ !are_redirect ]

  # Extract and store the logout
  are_logout <- extract(extra, "logout")

  ...multipage_opts$logout <- build_logout(
    extra[ are_logout ]
  )

  # We don't need the logout in extra
  extra <- extra[ !are_logout ]

  # Force a `/` page
  all_href <- vapply(
    pages, function(x){
      x$href
    }, FUN.VALUE = character(1)
  )

  if ( ! "/" %in% all_href ){
    stop("You must specify a root page (one with `href = '/')`.")
  }

  # Saving all the UIs
  x <- lapply(
    pages,
    function(x){
      ...multipage[[x$href]]$ui <- x$ui
    }
  )

  if (is.null(...multipage_opts$path)) {
    # Ignore the first time brochure() is called
    return()
  } else {
    # Removing the basepath
    url_hash <- gsub(basepath, "", ...multipage_opts$path)
    # Make sure you don't have multiple //
    url_hash <- gsub("/{2,}", "/", url_hash)

    id <- vapply(
      pages,
      function(x) x$href == url_hash,
      FUN.VALUE = logical(1)
    )

    wrapped(
      tagList(
        htmltools::includeScript(
          system.file("redirect.js", package = "brochure")
        ),
        extra,
        pages[[
          which(id)
          ]]$ui
      )
    )
  }

}
