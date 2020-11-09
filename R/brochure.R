...multipage <- new.env()

#' Create a brochureApp
#'
#' @inheritParams shiny::shinyApp
#' @importFrom shiny shinyApp
#'
#' @return A shiny.appobj
#' @export
brochureApp <- function(
  ui,
  server,
  onStart = NULL,
  options = list(),
  enableBookmarking = NULL
){
  # We add this enabled, just to be sure
  # `brochure_enable` is called inside a
  # `brochureApp`
  ...multipage$enabled <- TRUE
  shinyApp(
    ui = ui,
    server = server,
    onStart = onStart,
    options = options,
    uiPattern = ".*",
    enableBookmarking = enableBookmarking
  )
}

#' A Brochure Page
#'
#' @param href The endpoint to serve the UI on
#' @param ui Content served at `/href`
#'
#' @return A list
#' @export
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

#' Create the UI for a Brochure
#'
#' @param ... a list of `Page()`
#' @param wrapped A UI function wrapping the Brochure UI.
#' Default is `shiny::fluidPage`.
#'
#' @return
#' @export
#' @importFrom shiny uiOutput renderUI
brochure <- function(
  ...,
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

  all_href <- vapply(
    pages, function(x){
      x$href
    }, FUN.VALUE = character(1)
  )

  # Check that we have a home at /
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
      ...multipage[[x$href]]$renderFunc <- shiny::renderUI
    }
  )

  wrapped(
    tagList(
      extra,
      shiny::uiOutput("multipageui")
    )
  )

}

#' Enable Multipage via Brochure
#'
#' @return Used for sided effect
#'
#' @importFrom shiny getDefaultReactiveDomain renderUI tagList h1
#' @export
brochure_enable <- function(){
  # Stop if we're not in a brochureApp
  if (
    is.null(...multipage$enabled) ||
    !...multipage$enabled
  ){
    stop("Brochure not enabled. \nHave you used `brochureApp()` to run your app?")
  }

  output <- get("output", envir = parent.frame())

  observe({
    session <- getDefaultReactiveDomain()
    url_hash <- session$clientData$url_pathname
    # If ever the hash is empty, turn it to /
    # I'm not sure it's necessary anymore, TODO: check
    if (url_hash == ""){
      url_hash <- "/"
    }

    # We throw a NOT FOUND if the page isn't linked
    if (
      !url_hash %in% names(...multipage)
    ){
      output$multipageui <- renderUI({
        tagList(
          h1("Not found")
        )
      })
    } else {
      # Look for the page and render it
      output$multipageui <- ...multipage[[
        url_hash
      ]]$renderFunc(
        ...multipage[[
          url_hash
        ]]$ui
      )
    }
  })
}
