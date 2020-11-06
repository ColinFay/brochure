
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

This is a basic example which shows you how to solve a common problem:

``` r
library(brochure)
library(shiny)

ui <- function(request){
  brochure(
    page(
      href = "/",
      ui = tagList(
        h1("This is my first page"),
        tags$button(onclick = "window.location.href='page2'", "Next"),
        plotOutput("plota")
      )
    ),
    page(
      href = "/page2",
      ui =  tagList(
        h1("This is my second page"),
        fluidRow(
          tags$button(onclick = "window.location.href='/'", "Previous"),
          tags$button(onclick = "window.location.href='contact'", "Next")
        ),
        plotOutput("plotb")
      )
    ),
    page(
      href = "/contact",
      ui =  tagList(
        h1("Contact us"),
        tags$button(onclick = "window.location.href='page2'", "Previous"),
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
  
  brochure_enable()
  
  output$plota <- renderPlot({
    plot(mtcars)
  })
  
  output$plotb <- renderPlot({
    plot(airquality)
  })
  
}

brochureApp(ui, server)
```
