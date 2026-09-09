library(shiny)
library(brochure)
# Creating a navlink
nav_links <- tags$ul(
  tags$li(
    tags$a(href = "/", "home"),
  ),
  tags$li(
    tags$a(href = "/page2", "page2"),
  ),
  tags$li(
    tags$a(href = "/contact", "contact"),
  )
)

page_1 <- function() {
  page(
    href = "/",
    ui = function(request) {
      tagList(
        h1("This is my first page"),
        nav_links,
        plotOutput("plot")
      )
    },
    server = function(input, output, session) {
      output$plot <- renderPlot({
        plot(mtcars)
      })
    }
  )
}

page_2 <- function() {
  page(
    href = "/page2",
    ui = function(request) {
      tagList(
        h1("This is my second page"),
        nav_links,
        actionButton("to_contact", "Take me to contact"),
        plotOutput("plot")
      )
    },
    server = function(input, output, session) {
      output$plot <- renderPlot({
        plot(mtcars)
      })
      observeEvent(input$to_contact, {
        server_redirect("/contact")
      })
    }
  )
}

page_contact <- function() {
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
}

# A parameterised route: the matched values are read with get_keys()
page_who <- function() {
  page(
    href = "/who/:id",
    ui = function(request) {
      tagList(
        h1(sprintf("Hello %s", get_keys(request)$id)),
        nav_links,
        verbatimTextOutput("from_server")
      )
    },
    server = function(input, output, session) {
      output$from_server <- renderText({
        sprintf("server sees %s", get_keys()$id)
      })
    }
  )
}

brochureApp(
  # Pages
  page_1(),
  page_2(),
  page_contact(),
  page_who(),
  # Redirections
  redirect(
    from = "/page3",
    to = "/page2"
  ),
  redirect(
    from = "/page4",
    to = "/"
  )
)
