# Do a server side redirection

Do a server side redirection

## Usage

``` r
server_redirect(to, session = shiny::getDefaultReactiveDomain())
```

## Arguments

- to:

  the destination of the redirection: a path (`"/page2"`) or an
  `http(s)` URL. Other schemes are rejected.

- session:

  shiny session object, default is
  [`shiny::getDefaultReactiveDomain()`](https://rdrr.io/pkg/shiny/man/domains.html)

## Value

Used for side effect

## See also

[`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)
to answer an url with an HTTP redirection instead.

## Examples

``` r
library(shiny)

# `server_redirect()` is called from a page server, so it needs a session:
page(
  href = "/login",
  ui = tagList(actionButton("go", "Take me home")),
  server = function(input, output, session) {
    observeEvent(input$go, {
      server_redirect("/")
    })
  }
)
#> $href
#> [1] "/login"
#> 
#> $ui
#> <button id="go" type="button" class="btn btn-default action-button"><span class="action-label">Take me home</span></button>
#> 
#> $server
#> function (input, output, session) 
#> {
#>     observeEvent(input$go, {
#>         server_redirect("/")
#>     })
#> }
#> <environment: 0x564abb9dfd78>
#> 
#> $method
#> [1] "get"
#> 
#> $req_handlers
#> list()
#> 
#> $res_handlers
#> list()
#> 
#> attr(,"class")
#> [1] "brochure_page" "list"         
```
