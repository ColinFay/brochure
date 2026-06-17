library(shiny)
library(brochure)

# Repro Phase 0 : sous-page sur Posit Connect
# On veut reproduire le 404 des ressources (jquery, shiny.min.js, ...)
# quand on visite une page profonde AVEC slash final, p.ex.
#   https://connect.thinkr.fr/<mount>/page1/sous-page/

# Liens de navigation : on met bien un slash final sur la sous-page
# car c'est ce slash (profondeur du "répertoire" du document) qui
# casse la résolution de <base href="_w_token/"> injecté par Connect.
nav_links <- tags$ul(
  tags$li(tags$a(href = "/", "home")),
  tags$li(tags$a(href = "/page1", "page1 (1 segment)")),
  tags$li(tags$a(href = "/page1/sous-page/", "page1/sous-page/ (profond + slash)"))
)

home <- function() {
  page(
    href = "/",
    ui = tagList(
      h1("Home (/)"),
      nav_links,
      # Force le chargement de jQuery + shiny.min.js + htmlwidgets-like deps
      textInput("txt", "Un input"),
      plotOutput("plot")
    ),
    server = function(input, output, session) {
      output$plot <- renderPlot(plot(mtcars))
    }
  )
}

page1 <- function() {
  page(
    href = "/page1",
    ui = tagList(
      h1("Page 1 (/page1) - 1 segment, sans slash final"),
      nav_links,
      plotOutput("plot")
    ),
    server = function(input, output, session) {
      output$plot <- renderPlot(plot(airquality))
    }
  )
}

# LA page qui casse : 2 segments + visitée avec slash final
sous_page <- function() {
  page(
    href = "/page1/sous-page",
    ui = tagList(
      h1("Sous-page (/page1/sous-page/) - profonde"),
      nav_links,
      textInput("txt2", "Un input ici aussi"),
      plotOutput("plot")
    ),
    server = function(input, output, session) {
      output$plot <- renderPlot(plot(iris))
    }
  )
}

brochureApp(
  home(),
  page1(),
  sous_page()
)
