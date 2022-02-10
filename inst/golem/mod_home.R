#' home UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_home_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h1("Hello {brochure}!")
  )
}

#' home Server Functions
#'
#' @noRd
mod_home_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
  })
}

#' Page Functions
#'
#' @noRd
#' @importFrom brochure page
home <- function(id = "home", href = "/") {
  page(
    href = href,
    ui = mod_home_ui(id = id),
    server = function(input, output, session) {
      mod_home_server(id = id)
    }
  )
}

# Add this to the brochureApp call in R/run_app.R
# home()
