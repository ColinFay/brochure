# A Brochure Page

A Brochure Page

## Usage

``` r
page(
  href,
  ui = tagList(),
  server = function(input, output, session) {
 },
  req_handlers = list(),
  res_handlers = list()
)
```

## Arguments

- href:

  The endpoint to serve the UI on

- ui:

  The UI definition of the app (for example, a call to
  [`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html) with
  nested controls).

  If bookmarking is enabled (see `enableBookmarking`), this must be a
  single argument function that returns the UI definition.

- server:

  A function with three parameters: `input`, `output`, and `session`.
  The function is called once for each session ensuring that each app is
  independent.

- req_handlers:

  a list of functions that can manipulate the `req` object. These
  functions should take `req` as a parameters, and return the `req`
  object (potentially modified), or an object of class httpResponse. If
  any of the req_handlers return an httpResponse, this response will be
  sent to the browser immeditately, stopping any other code.

- res_handlers:

  A list of functions that can manipulate the httpResponse object before
  it is send to the browser. Each function must take a `res` and `req`
  parameter.

## Value

A list

## Examples

``` r
library(shiny)
page(
  href = "/page2",
  ui = tagList(
    h1("This is my second page"),
    plotOutput("plotb")
  )
)
#> $href
#> [1] "/page2"
#> 
#> $ui
#> <h1>This is my second page</h1>
#> <div class="shiny-plot-output html-fill-item" id="plotb" style="width:100%;height:400px;"></div>
#> 
#> $server
#> function (input, output, session) 
#> {
#> }
#> <environment: 0x555f2a4b2130>
#> 
#> attr(,"class")
#> [1] "brochure_page" "list"         
```
