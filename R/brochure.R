...multipage <- new.env()
...multipage_opts <- new.env()

#' A Brochure Page
#'
#' @param href The endpoint to serve the UI on
#' @param ui Content served at `/href`
#'
#' @return A list
#' @export
#'
#' @importFrom shiny tagList
#'
#' @examples
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
  ui
){
  # Page are href + ui
  res <- list(
    href = href,
    ui = tagList(ui)
  )
  class(res) <- c("brochure_page", class(res))
  res
}

#' Redirection
#'
#' @param from redirect from
#' @param to redirect to
#'
#' @return A redirection
#' @export
redirect <- function(
  from,
  to,
  code = 301
){
  attempt::stop_if(
    code,
    ~ !.x %in% c(301:308, 310),
    sprintf(
      "Redirect code should be one of %s.",
      paste(c(301:308, 310), collapse = " ")
    )
  )
  res <- list(
    from = from,
    to = to,
    code = code
  )
  class(res) <- c("redirect", class(res))
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
#'
#' @return
#' @export
#' @importFrom shiny tagList
brochure <- function(
  ...,
  basepath = "",
  wrapped = shiny::fluidPage
){
  content <- list(...)
  # Separate the extra content from the pages
  # This allows to add extra deps
  are_pages <- vapply(content, function(x) {
    inherits(x, "brochure_page")
  }, logical(1))

  pages <- content[
    are_pages
    ]

  extra <- content[
    !are_pages
    ]

  # Extract and store the redirects
  are_redirect <- vapply(extra, function(x) {
    inherits(x, "redirect")
  }, logical(1))

  redirect <- extra[
    are_redirect
    ]
  ...multipage_opts$redirect <- do.call(
    rbind,
    lapply(redirect, function(x){
      data.frame(
        from = x$from,
        to = x$to,
        code = x$code
      )
    })
  )

  # We don't need the redirect in extra
  extra <- extra[
    !are_redirect
  ]

  # Force a `/` page
  all_href <- vapply(
    pages, function(x){
      x$href
    }, FUN.VALUE = character(1)
  )

  if (
    ! "/" %in% all_href
  ){
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
        extra,
        pages[[
          which(id)
          ]]$ui
      )
    )
  }

}
