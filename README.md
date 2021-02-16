
<!-- README.md is generated from README.Rmd. Please edit that file -->

# brochure

<!-- badges: start -->

[![R build
status](https://github.com/ColinFay/brochure/workflows/R-CMD-check/badge.svg)](https://github.com/ColinFay/brochure/actions)
<!-- badges: end -->

**THIS IS A WORK IN PROGRESS, DO NOT USE**

The goal of `{brochure}` is to provide a mechanism for creating natively
multi-page `{shiny}` applications, *i.e* that can serve content on
multiple endpoints.

**Disclaimer**: the way you will build app with `{brochure}` is
different from the way you usually build `{shiny}` apps, as we no longer
operate under the single page app paradigm. Please read the “Design
Pattern” of this README for more info.

## Installation

You can install the released version of `{brochure}` with:

``` r
remotes::install_github("ColinFay/brochure")
```

``` r
library(brochure)
#> 
#> Attaching package: 'brochure'
#> The following object is masked from 'package:utils':
#> 
#>     page
library(shiny)
```

## Minimal `{brochure}` App

### `page()`

A `brochureApp` is a series of `page`s that are defined by an `href`
(the path/endpoint where the page is available), a `{shiny}` UI and a
`server` function. This is conceptually important: each page has its own
shiny session, its own UI, and its own server.

Note that the server is optional if you want to display a static page.

``` r
brochureApp(
  # First page
  page(
    href = "/",
    ui = fluidPage(
      h1("This is my first page"), 
      plotOutput("plot")
    ),
    server = function(input, output, session){
      output$plot <- renderPlot({
        plot(iris)
      })
    }
  ), 
  # Second page, without any server-side function
  page(
    href = "/page2", 
    ui =  fluidPage(
      h1("This is my second page"), 
      tags$p("There is no server function in this one")
    )
  )
)
```

> You can now navigate to /, and to /page2 inside your browser.

### `redirect()`

Redirections can be used to redirect from one endpoint to the other:

``` r
brochureApp(
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
```

> You can now navigate to /nothere, you’ll be redirected to /

A more elaborate example:

``` r
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

page_1 <- function(){
  page(
    href = "/",
    ui = function(request){
      tagList(
        h1("This is my first page"),
        nav_links,
        plotOutput("plot")
      )
    },
    server = function(input, output, session){
      output$plot <- renderPlot({
        plot(mtcars)
      })
    }
  )
}

page_2 <- function(){
  page(
    href = "/page2",
    ui =  function(request){
      tagList(
        h1("This is my second page"),
        nav_links,
        plotOutput("plot")
      )
    }, 
    server = function(input, output, session){
      output$plot <- renderPlot({
        plot(mtcars)
      })
    }
  )
}

page_contact <- function(){
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
}

brochureApp(
  # Pages
  page_1(),
  page_2(),
  page_contact(),
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
```

## `req_handlers` & `res_handlers`

### Sorry what?

Each page, and the app, have a `req_handlers` and `res_handlers`
parameters, that can take a list of functions. An `_handler` is a
function that takes as argument(s): - `req`, the request object, for
`req_handlers` - `res`, the response object, & `req` for `res_handlers`

`req_handlers` **must** return `req` & `res_handlers` **must** return
`res`, potentially modified.

They can be used to register log, or to modify the objects, or any kind
of things you can think of. If you are familiar with `express.js`, you
can think of `req_handlers` as what express calls “middleware”. These
functions are run when R is building the HTTP response to send to the
browser (i.e, no server code has been run yet), following this process:

1.  R receives a `GET` request from the browser, creating a request
    object, called `req`
2.  The `req_handlers` are run using this `req` object
3.  R creates an `httpResponse`, using this `req` and how you defined
    the UI
4.  The `res_handlers` are run on this `httpResponse` (first app level
    `res_handlers`, then page level `res_handlers`)
5.  The `httpResponse` is sent back to the browser

Note that if any `req_handlers` returns an `httpResponse` object, it
will be returned to the browser immediately, without any further
computation. This early `httpResponse` will not be passed to the
`res_handlers`.

You can use formulas inside your handlers. `.x` and `..1` will be `req`
for req\_handlers, `.x` and `..1` will be `res` & `.y` and `..2` will be
`req` for res\_handlers.

Design pattern side-note: you’d probably want to define the handlers
outside of the app, for better code organization (as with `log_where`
below).

### Example: Logging with `req_handlers()`, and building a healthcheck point

In this app, we’ll log to the console every page and the time it is
called, using the `log_where()` function.

``` r
log_where <- function(req){
  cli::cat_rule(
    sprintf(
      "%s - %s", 
      Sys.time(), 
      req$PATH_INFO
    )
  )
  req
}
```

We’ll also build an `healthcheck` endpoint that simply returns a 200
`httpResponse`.

``` r
# Reusing the pages from before
brochureApp(
  req_handlers = list(
    log_where
  ),
  # Pages
  page_1(),
  page_2(),
  page_contact(),
  page(
    href = "/healthcheck",
    # As this is a pure backend exchange, 
    # We don't need a UI
    ui =  tagList(), 
    # As this req_handler returns an httpResponse,
    # This response will be returned directly to the browser, 
    # without passing through the usual shiny http dance
    req_handlers = list(
      # If you have shiny < 1.6.0, you'll need to 
      # do shiny:::httpResponse (triple `:`) 
      # as it is not exported until 1.6.0.
      # Otherwise, see ?shiny::httpResponse
      ~ shiny::httpResponse( 200, content = "OK")
    )
  )
)
```

If you go to another R session, you can check that you’ve got a 200 on
`healthcheck`

``` r
> httr::GET("http://127.0.0.1:4879/healthcheck")
Response [http://127.0.0.1:4879/healthcheck]
  Date: 2021-02-16 19:47
  Status: 200
  Content-Type: text/html; charset=UTF-8
  Size: 2 B
```

### Handling cookies using `res_handlers`

`res_handlers` can be used to set cookies, by adding a `Set-Cookie`
header.

Note that you can parse the cookie using `parse_cookie_string`.

``` r
parse_cookie_string( "a=12;session=blabla" )
#>        a  session 
#>     "12" "blabla"
```

In the example, we’ll also use `brochure::server_redirect("/")` to
redirect the user after login.

``` r
# Creating a navlink
nav_links <- tags$ul(
  tags$li(
    tags$a(href = "/", "home"), 
  ),
  tags$li(
    tags$a(href = "/login", "login"), 
  ),
  tags$li(
    tags$a(href = "/logout", "logout"), 
  )
)

home <- function(){
  page(
    href = "/",
    ui = tagList(
      h1("This is my first page"), 
      tags$p("It will contain BROCHURECOOKIE depending on the last page you've visited (/login or /logout)"),
      verbatimTextOutput("cookie"),
      nav_links
    ),
    server = function(input, output, session){
      output$cookie <- renderPrint({
        parse_cookie_string(
          session$request$HTTP_COOKIE
        )
      })
    }
  )
}

login <- function(){
  page(
    href = "/login",
    ui =  tagList(
      h1("You've just logged!"),
      verbatimTextOutput("cookie"),
      actionButton("redirect", "Redirect to the home page"),
      nav_links
    ), 
    server = function(input, output, session){
      output$cookie <- renderPrint({
        parse_cookie_string(
          session$request$HTTP_COOKIE
        )
      })
      observeEvent( input$redirect , {
        # Using brochure to redirect to another page
        server_redirect("/")
      })
      
    },
    res_handlers = list(
      # We'll add a cookie here
      function(res, req){
        res$headers$`Set-Cookie` <- "BROCHURECOOKIE=12; HttpOnly;"
        res
      }
    )
  )
}

logout <- function(){
  page(
    href = "/logout",
    ui =  tagList(
      h1("You've logged out"),
      nav_links,
      verbatimTextOutput("cookie")
    ), 
    server = function(input, output, session){
      output$cookie <- renderPrint({
        parse_cookie_string(
          session$request$HTTP_COOKIE
        )
      })
    },
    res_handlers = list(
      # We'll add a cookie here
      function(res, req){
        res$headers$`Set-Cookie` <- "BROCHURECOOKIE=12; Expires=Wed, 21 Oct 1950 07:28:00 GMT"
        res
      }
    )
  )
}

brochureApp(
  # Pages
  home(),
  login(),
  logout()
)
```

## Design pattern

Note that every time you open a new page, a **new shiny session is
launched**. This is different from what you usually do when you are
building a `{shiny}` app that works as a single page application. This
is no longer the case in `{brochure}`.

What that means is that there is no data persistence in R when
navigating from one page to the other. That might seem like a downside,
but I believe that it will actually be for the best: it will make
developers think more carefully about the data flow of their
application.

That being said, how do we keep track of a user though pages, so that if
they do something in a page, it’s reflected on another?

To do that, you’d need to add a form of session identifier, like a
cookie: this can for example be done using the
[`{glouton}`](https://github.com/colinfay/glouton) package if you want
to manage it with JS. You can also use the cookie example from before.

You’ll also need a form of backend storage (here in the example, we use
[`{cachem}`](https://github.com/r-lib/cachem), but you can also use an
external DB like SQLite or MongoDB).

``` r
library(glouton)
# Creating a storage system
cache_system <- cachem::cache_disk(tempdir())

nav_links <- tags$ul(
  tags$li(
    tags$a(href = "/", "home"), 
  ),
  tags$li(
    tags$a(href = "/page2", "page2"), 
  )
)

cookie_set <- function(){
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
  }, once = TRUE)
  return(r)
}

page_1 <- function(){
  page(
    href = "/",
    ui = tagList(
      h1("This is my first page"),
      nav_links,
      # The text enter on page 1 will be available on page 2, using
      # a session cookie and a storage system
      textInput("textenter", "Enter a text"), 
      actionButton("save", "Save my text and go to page2")
    ),
    server = function(input, output, session){
      r <- cookie_set()
      observeEvent( input$save , {
        # Use the session id to save on the cache system
        cache_system$set(
          paste0(
            r$cook$brochure_cookie,
            "text"
          ),
          input$textenter
        )
        server_redirect("/page2")
      })
    }
  )
}

page_2 <- function(){
  page(
    href = "/page2",
    ui =  tagList(
      h1("This is my second page"),
      nav_links,
      # The text enter on page 1 will be available here, reading
      # the storage system
      verbatimTextOutput("textdisplay")
    ), 
    server = function(input, output, session){
      r <- cookie_set()
      output$textdisplay <- renderPrint({
        # Getting the content value based on the session cookie
        cache_system$get(
          paste0(
            r$cook$brochure_cookie,
            "text"
          )
        )
      })
    }
  )
}

brochureApp(
  # Setting {glouton} globally
  use_glouton(),
  # Pages
  page_1(),
  page_2()
  # Redirections
)
```

## With golem

To adapt your `{golem}` based application to `{brochure}`, here are the
two steps to follow:

  - Remove the app\_server.R file, and the top of app\_ui =\> You’ll
    still need `golem_add_external_resources()`.

  - Build the pages inside separate R scripts, following the example
    from this `README`.

<!-- end list -->

    .
    ├── DESCRIPTION
    ├── NAMESPACE
    ├── R
    │   ├── app_config.R
    │   ├── home.R ### YOUR PAGE 
    │   ├── login.R ### YOUR PAGE 
    │   ├── logout.R ### YOUR PAGE 
    │   └── run_app.R ### YOUR PAGE 
    ├── dev
    │   ├── 01_start.R
    │   ├── 02_dev.R
    │   ├── 03_deploy.R
    │   └── run_dev.R
    ├── inst
    │   ├── app
    │   │   └── www
    │   │       ├── favicon.ico
    │   └── golem-config.yml
    ├── man
    │   └── run_app.Rd

  - Replace `shinyApp` with `brochureApp` in `run_app()`, add the
    external resources, then your pages.

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
      # Putting the resources here
      golem_add_external_resources(),
      home(),
      login(),
      logout(),
      onStart = onStart,
      options = options, 
      enableBookmarking = enableBookmarking
    ), 
    golem_opts = list(...)
  )
}
```
