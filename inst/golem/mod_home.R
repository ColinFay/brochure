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
home <- function() {
    page(
        href = "/",
        ui = mod_home_ui,
        server = mod_home_server
    )
}
