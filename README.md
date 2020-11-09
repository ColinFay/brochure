
<!-- README.md is generated from README.Rmd. Please edit that file -->

# brochure

<!-- badges: start -->

<!-- badges: end -->

**THIS IS A WORK IN PROGRESS, DO NOT USE**

The goal of `{brochure}` is to provide a mechanism for deploying
multi-page `{shiny}` application, *i.e* that can serve content on
multiple endpoints.

## Installation

You can install the released version of `{brochure}` with:

``` r
remotes::install_github("ColinFay/brochure")
```

## Example

``` r
library(brochure)
library(shiny)

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

ui <- function(request){
  brochure(
    page(
      href = "/",
      ui = tagList(
        h1("This is my first page"),
        nav_links,
        plotOutput("plota")
      )
    ),
    page(
      href = "/page2",
      ui =  tagList(
        h1("This is my second page"),
        nav_links,
        plotOutput("plotb")
      )
    ),
    page(
      href = "/contact",
      ui =  tagList(
        h1("Contact us"),
        nav_links,
        tags$ul(
          tags$li("Here"),
          tags$li("There")
        )
      )
    )
  )
}

server <- function(
  input, 
  output, 
  session
){
  
  # RENDERED ON ALL PAGES
  brochure_enable()
  
  # THIS PART WILL ONLY BE RENDERED ON /
  output$plota <- renderPlot({
    print("In /")
    plot(mtcars)
  })
  
  # THIS PART WILL ONLY BE RENDERED ON /page2
  output$plotb <- renderPlot({
    print("In /page2")
    plot(airquality)
  })
  
}

brochureApp(ui, server)
```

## Design pattern

Note that every time you open a new page, a **new shiny session is
launched**.

What that means is that there is no data persistence in R when
navigating from one page to the other. That might seem like a downside,
but I believe that it will actually be for the best: it will make
developers think more carefully about the data flow of their
application;

That being said, how do keep track of a user though pages, so that if
they do something in a page, it’s reflected on another?

To do that, you’d need to add a form of session identifier, like a
cookie: this can for example be done using the
[`{glouton}`](https://github.com/colinfay/glouton) package. You’ll also
need a form of backend storage (here in the example, we use
[`{cachem}`](https://github.com/r-lib/cachem), but you can also use an
external DB like SQLite or MongoDB).

``` r
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


ui <- function(request){
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
        textInput("textenter", "Enter a text"),
        plotOutput("plota")
      )
    ),
    page(
      href = "/page2",
      ui =  tagList(
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
      ui =  tagList(
        h1("Contact us"),
        nav_links,
        tags$ul(
          tags$li("Here"),
          tags$li("There")
        )
      )
    )
  )
}

server <- function(
  input, 
  output, 
  session
){
  
  # THIS PART WILL BE RENDERED ON ALL PAGES
  
  # Enabling the brochure mechanism
  brochure_enable()
  
  r <- reactiveValues()
  
  observeEvent(TRUE, {
    # Fetch the cookies using {glouton}
    r$cook <- fetch_cookies()
    
    # If there is no stored cookie for {brochure}, we generate it
    if (is.null(r$cook$brochure_cookie)){
      # Generate a random id
      session_id <- digest::sha1(paste(Sys.time(), sample(letters, 16)))
      # Add this id as a cookie
      add_cookie("brochure_cookie", session_id)
      # Store in in the reactiveValues list
      r$cook$brochure_cookie <- session_id
    }
    # For debugging purpose
    print(r$cook$brochure_cookie )
  }, 
  # We only need to do it once doing it once
  once = TRUE
  )
  
  # THIS PART WILL ONLY BE RENDERED ON /
  
  observeEvent( input$textenter , {
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
```
