#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`.
#'     DO NOT REMOVE.
#' @import shiny
#' @import brochure
#' @import glouton
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    # Your application UI logic
    brochure(
      # We add an extra dep to the brochure page, here {glouton}
      use_glouton(),
      page(
        href = "/",
        ui = tagList(
          h1("This is my first page"),
          nav_links,
          # The text enter on page 1 will be available on page 2, using
          # a session cookie and a storage system
          textInput("textenter", "Enter a text here - it will appear on page 2"),
          plotOutput("plota")
        )
      ),
      page(
        href = "/page2",
        ui = tagList(
          h1("This is my second page"),
          nav_links,
          # The text enter on page 1 will be available here, reading
          # the storage system
          p("This is the text you entered on the first page"),
          verbatimTextOutput("textdisplay"),
          plotOutput("plotb")
        )
      ),
      page(
        href = "/contact",
        ui = tagList(
          h1("Contact us"),
          nav_links,
          tags$ul(
            tags$li("Here"),
            tags$li("There")
          )
        )
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "brochure"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
