...multipage <- new.env()
...multipage_opts <- new.env()

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
  ...multipage_opts$enabled <- TRUE
  # Force UI if it hasn't been evaluated yet
  # So that we are sure `...multipage` are
  # enable
  if (is.function(ui)) ui()
  res <- shinyApp(
    ui = ui,
    server = server,
    onStart = onStart,
    options = options,
    uiPattern = ".*",
    enableBookmarking = enableBookmarking
  )
  old_httpHandler <- res$httpHandler
  res$httpHandler <- function(req){
    #browser()
    # Returning a 404 if the page doesn't exist
    if (!req$PATH_INFO %in% names(...multipage)){
      httpResponse <- getFromNamespace("httpResponse", "shiny")
      return(httpResponse(
        status = 404,
        content = "Not found"
      ))
    }
    # Setting the path info for reuse in brochure()
    ...multipage_opts$path <- req$PATH_INFO
    # Note to self:
    # req$HTTP_COOKIE
    old_httpHandler(req)
  }
  res
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
#' @param basepath The base path of your app. This pattern will be removed from the
#' url, so that it matches the href of your `page()`. For example, it you have
#' an app at `http://connect.thinkr.fr/brochure/`, and your page is names `page1`,
#' use `basepath = "brochure"`
#'
#' @return
#' @export
#' @importFrom shiny uiOutput renderUI
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

  # Force a `/` page
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
    id <- vapply(pages, function(x) x$href == url_hash, FUN.VALUE = logical(1))
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

#' #' Enable Multipage via Brochure
#' #'
#' #' @param basepath The base path of your app. This pattern will be removed from the
#' #' url, so that it matches the href of your `page()`. For example, it you have
#' #' an app at `http://connect.thinkr.fr/brochure/`, and your page is names `page1`,
#' #' use `basepath = "brochure"`
#' #'
#' #' @return Used for sided effect
#' #'
#' #' @importFrom shiny getDefaultReactiveDomain renderUI tagList h1
#' #' @export
#' brochure_enable <- function(
#'   basepath = ""
#' ){
#'
#'   # Stop if we're not in a brochureApp
#'   if (
#'     is.null(...multipage_opts$enabled) ||
#'     !...multipage_opts$enabled
#'   ){
#'     stop("Brochure not enabled. \nHave you used `brochureApp()` to run your app?")
#'   }
#'
#'   output <- get("output", envir = parent.frame())
#'
#'   observe({
#'     session <- getDefaultReactiveDomain()
#'     url_hash <- session$clientData$url_pathname
#'     # If ever the hash is empty, turn it to /
#'     # I'm not sure it's necessary anymore, TODO: check
#'     if (url_hash == ""){
#'       url_hash <- "/"
#'     }
#'     # Removing the basepath
#'     url_hash <- gsub(basepath, "", url_hash)
#'     # Make sure you don't have multiple //
#'     url_hash <- gsub("/{2,}", "/", url_hash)
#'
#'     # Look for the page and render it
#'     output$multipageui <- ...multipage[[
#'       url_hash
#'     ]]$renderFunc(
#'       ...multipage[[
#'         url_hash
#'       ]]$ui
#'     )
#'
#'   })
#' }
