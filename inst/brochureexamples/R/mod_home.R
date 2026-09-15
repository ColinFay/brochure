#' Home page ("/")
#'
#' Each brochure page bundles its own UI and server.
#'
#' @import shiny
#' @import brochure
#' @import glouton
#' @noRd
home <- function() {
  page(
    href = "/",
    ui = tagList(
      h1("This is my first page"),
      nav_links,
      # The text entered here will be available on page2, via a session
      # cookie + the shared cache_system store.
      textInput("textenter", "Enter a text here - it will appear on page 2"),
      plotOutput("plota")
    ),
    server = function(input, output, session) {
      r <- reactiveValues()

      observeEvent(
        TRUE,
        {
          r$cookie <- fetch_brochure_cookie()
        },
        once = TRUE
      )

      observeEvent(input$textenter, {
        cache_system$set(
          paste0(r$cookie, "text"),
          input$textenter
        )
      })

      output$plota <- renderPlot({
        plot(mtcars)
      })
    }
  )
}
