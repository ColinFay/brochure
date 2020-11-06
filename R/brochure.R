...multipage <- new.env()

#' Create a brochureApp
#'
#' @inheritParams shiny::shinyApp
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
  list(
    href = href,
    ui = tagList(ui)
  )
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
#' @examples
brochure <- function(
  ...,
  wrapped = shiny::fluidPage
){
  content <- list(...)

  all_href <- vapply(
    content, function(x){
      x$href
    }, FUN.VALUE = character(1)
  )

  if (
    ! "/" %in% all_href
  ){
    stop("You must specify a root page (one with `href = '/')`.")
  }

  x <- lapply(
    content,
    function(x){
      ...multipage[[x$href]]$ui <- x$ui
      ...multipage[[x$href]]$renderFunc <- shiny::renderUI
    }
  )

  wrapped(
    shiny::uiOutput("multipageui")
  )

}

#' Enable Multipage via Brochure
#'
#' @return Used for sided effect
#'
#' @importFrom shiny getDefaultReactiveDomain renderUI tagList h1
#' @export
brochure_enable <- function(){
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
    if (url_hash == ""){
      url_hash <- "/"
    }

    if (
      !url_hash %in% names(...multipage)
    ){
      output$multipageui <- renderUI({
        tagList(
          h1("Not found")
        )
      })
    } else {
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
