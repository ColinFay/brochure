
<!-- README.md is generated from README.Rmd. Please edit that file -->

# brochure

<!-- badges: start -->

<!-- badges: end -->

**THIS IS A WORK IN PROGRESS, DO NOT USE**

The goal of `{brochure}` is to provide a mechanism for creating natively
multi-page `{shiny}` applications, *i.e* that can serve content on
multiple endpoints.

## Installation

You can install the released version of `{brochure}` with:

``` r
remotes::install_github("ColinFay/brochure")
```

## Example

Here is the minimal working example:

``` r
library(brochure)
library(shiny)

ui <- function(request){
  brochure(
    page(
      href = "/",
      ui = tagList(
        h1("This is my first page")
      )
    ),
    page(
      href = "/page2",
      ui =  tagList(
        h1("This is my second page")
      )
    )
  )
}

server <- function(
  input, 
  output, 
  session
){
  
}

brochureApp(ui, server)
```

Redirections can be used to redirect from one endpoint to the other:

``` r
ui <- function(request){
  brochure(
    page(
      href = "/",
      ui = tagList(
        h1("This is my first page")
      )
    ),
    redirect(
      from = "/nothere",
      to =  "/"
    )
  )
}

server <- function(
  input, 
  output, 
  session
){
  
}

brochureApp(ui, server)
```

All app, by default set a session cookie in the browser that can be
caught in the server. To remove this cookie, you need to redirect to a
`logout` page:

``` r
library(shiny)
ui <- function(request){
  brochure(
    page(
      href = "/",
      ui = tagList(
        h1("This is my first page"), 
        tags$a(href = "/page2", "page2"), 
        tags$a(href = "/logout", "log out"), 
        verbatimTextOutput("cookie")
      )
    ),
    page(
      href = "/page2",
      ui = tagList(
        h1("This is my second page"), 
        tags$a(href = "/", "home"), 
        tags$a(href = "/logout", "log out"), 
        verbatimTextOutput("cookie2")
      )
    ),
    logout(
      href = "/logout",
      redirect_to = "/"
    )
  )
}

server <- function(
  input, 
  output, 
  session
){
  
  output$cookie <- renderPrint({
    get_brochure_cookie()
  })
  output$cookie2 <- renderPrint({
    get_brochure_cookie()
  })
  
}

brochureApp(ui, server)
```

And a more elaborate one:

``` r
library(brochure)
library(shiny)

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

ui <- function(request){
  brochure(
    # Pages
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
    ),
    # Redirections
    redirect(
      from = "/page3",
      to =  "/page2"
    ),
    redirect(
      from = "/page4",
      to =  "/"
    )
  )
}

server <- function(
  input, 
  output, 
  session
){
  
  # THIS PART WILL BE RENDERED ON /
  output$plota <- renderPlot({
    print("In /")
    plot(mtcars)
  })
  
  # THIS PART WILL BE RENDERED ON /page2
  output$plotb <- renderPlot({
    print("In /page2")
    plot(airquality)
  })
  
}

brochureApp(ui, server)
```

## Middlewares & finalizers

You can add middlewares and finalizers at the app & at each page level.
A (middleware/finalizer is a function that takes one argument, `req`
(middleware) or `req` and `http_response` (finalizer), and return `req`
(middleware) & `http_response` (finalizer), potentially modified. Each
page & the app have a `middleware` parameter, that can take a list of
these functions.

They can be used to register log, or to modify the `req` object, or any
kind of things you can think of. They are run when R is building the
HTTP response to send to the browser (i.e, no server code has been run
yet).

Note that if any of these middleware returns an `httpResponse` object,
it will be returned to the browser immediately, without any further
computation.

Finalizers, on the other hands, are runs on the final `httpResponse`
object return by R. In other words: - R receives a `GET` request from
the browser, with a `req` object. - The middlewares are run using this
req - R createsan `httpResponse` based on the `brochure` definition -
The finalizers are run on this `httpResponse` (first app level, then
page level) - The `httpResponse` is returned to the browser

### Middleware demo

``` r
library(brochure)
library(shiny)

ui <- function(request){
  brochure(
    middleware = list(
      function(req){
        print("ALL PAGE")
        req
      }
    ),
    page(
      href = "/",
      ui = tagList(
        h1("This is my first page")
      ), 
      middleware = list(
        function(req){
          print("HOME")
          req
        }
      )
    ),
    page(
      href = "/page2",
      ui =  tagList(
        h1("This is my second page")
      )
    )
  )
}

server <- function(
  input, 
  output, 
  session
){
  
}

brochureApp(ui, server)
```

### Finalizer demo

Finalizers can be interesting to set cookies

``` r
library(brochure)
library(shiny)

ui <- function(request){
  brochure(
    finalizer = list(
      function(http_resp, req){
        qs <- shiny::parseQueryString(req$QUERY_STRING)
        if (
          length(qs) == 0
        ){
          http_resp$headers$`Set-Cookie` <- "plop=12; HttpOnly; Expires=Wed, 21 Oct 2050 07:28:00 GMT;Path=/"
        } else if ("logout" %in% names(qs)){
          http_resp$headers$`Set-Cookie` <- "plop=12; HttpOnly; Expires=Wed, 21 Oct 1950 07:28:00 GMT;Path=/"
        }
        http_resp
      }
    ),
    page(
      href = "/",
      ui = tagList(
        h1("This is my first page"), 
        tags$p("Try reloading this page with ?logout in the url to remove the Cookie"), 
        verbatimTextOutput("cookie1")
      )
    ),
    page(
      href = "/page2",
      ui =  tagList(
        h1("This is my second page"),
        verbatimTextOutput("cookie2")
      )
    ), 
    page(
      href = "/logout",
      ui = tagList(
        "Bye"
      ), 
      finalizer = list( 
        function(http_resp, req){
          http_resp$headers$`Set-Cookie` <- "plop=12; HttpOnly; Expires=Wed, 21 Oct 1950 07:28:00 GMT;Path=/"
          http_resp
        }
      )
    )
  )
}

server <- function(
  input, 
  output, 
  session
){
  
  output$cookie1 <- renderPrint({
    session$request$HTTP_COOKIE
  })
  
  output$cookie2 <- renderPrint({
    session$request$HTTP_COOKIE
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
  # brochure_enable()
  
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

## With golem

To adapt your `{golem}` based application to `{brochure}`, here are the
two steps to follow:

  - Build the ui with `brochure()` and `page()` in `app_ui()` :

<!-- end list -->

``` r
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    # Your application UI logic 
    brochure(
      page(
        href = "/",
        ui = mod_home_ui("home_ui_1") 
      ), 
      page(
        href = "/01",
        ui = mod_01_ui("01_ui_1")
      )
    )
  )
}
```

  - Replace `shinyApp` with `brochureApp` in `app_server()`:

<!-- end list -->

``` r
run_app <- function(
  onStart = NULL,
  options = list(), 
  enableBookmarking = NULL,
  ...
) {
  with_golem_options(
    app = brochureApp(
      ui = app_ui,
      server = app_server,
      onStart = onStart,
      options = options, 
      enableBookmarking = enableBookmarking
    ), 
    golem_opts = list(...)
  )
}
```
