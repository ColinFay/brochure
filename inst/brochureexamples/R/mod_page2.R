#' Second page ("/page2")
#'
#' Reads back the text entered on the home page, using the session cookie and
#' the shared cache_system store.
#'
#' @import shiny
#' @import brochure
#' @import glouton
#' @noRd
page2 <- function() {
  page(
    href = "/page2",
    ui = tagList(
      h1("This is my second page"),
      nav_links,
      p("This is the text you entered on the first page"),
      verbatimTextOutput("textdisplay"),
      plotOutput("plotb")
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

      output$textdisplay <- renderPrint({
        req(r$cookie)
        cache_system$get(
          paste0(r$cookie, "text"),
          default = NULL
        )
      })

      output$plotb <- renderPlot({
        plot(airquality)
      })
    }
  )
}
