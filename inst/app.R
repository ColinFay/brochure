# remotes::install_github("colinfay/brochure")
# Launch the shinyApp
pkgload::load_all()
library(brochure)
library(glouton)
library(shiny)
# Creating a storage system
cache_system <- cachem::cache_disk("inst/cache")

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


ui <- function(request) {
  brochure(
    req_handlers = list(function(req) {
      cli::cat_rule(Sys.time())
      print(req$HEADERS[["host"]])
      print(req$PATH_INFO)
      req
    }),
    basepath = "brochure",
    # We add an extra dep to the brochure page, here {glouton}
    use_glouton(),
    page(
      href = "/",
      ui = tagList(
        h1("This is my first page"),
        nav_links,
        # The text enter on page 1 will be available on page 2, using
        # a session cookie and a storage system
        textInput("textenter", "Enter a text"),
        plotOutput("plota")
      )
    ),
    page(
      req_handlers = list(function(req) {
        print("coucou")
        req
      }),
      href = "/page2/:id:",
      ui = tagList(
        h1("This is my second page"),
        nav_links,
        # The text enter on page 1 will be available here, reading
        # the storage system
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
    ),
    redirect(
      "/blabla",
      "/page2"
    )
  )
}

server <- function(
  input,
  output,
  session
) {

  # THIS PART WILL BE RENDERED ON ALL PAGES

  # Enabling the brochure mechanism
  # brochure_enable()

  r <- reactiveValues()

  observeEvent(
    TRUE,
    {
      # Fetch the cookies using {glouton}
      r$cook <- fetch_cookies()

      # If there is no stored cookie for {brochure}, we generate it
      if (is.null(r$cook$brochure_cookie)) {
        # Generate a random id
        session_id <- digest::sha1(paste(Sys.time(), sample(letters, 16)))
        # Add this id as a cookie
        add_cookie("brochure_cookie", session_id)
        # Store in in the reactiveValues list
        r$cook$brochure_cookie <- session_id
      }
      # For debugging purpose
      print(r$cook$brochure_cookie)
    },
    # We only need to do it once doing it once
    once = TRUE
  )

  # THIS PART WILL ONLY BE RENDERED ON /

  observeEvent(input$textenter, {
    # Use the session id to save on the cache system
    cache_system$set(
      paste0(
        r$cook$brochure_cookie,
        "text"
      ),
      input$textenter
    )
  })



  output$plota <- renderPlot({
    print("In /")
    plot(mtcars)
  })

  # THIS PART WILL ONLY BE RENDERED ON /page2

  output$textdisplay <- renderPrint({
    # Getting the content value based on the session cookie
    cache_system$get(
      paste0(
        r$cook$brochure_cookie,
        "text"
      )
    )
  })

  output$plotb <- renderPlot({
    print("In /page2")
    plot(airquality)
  })
}

brochureApp(ui, server)
