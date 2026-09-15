# Get the keys of a parameterised page

A page declared with a parameterised `href` (e.g. `"/who/:id"`) exposes
the values matched in the URL through `get_keys()`. Call it with no
argument inside a page `server`, and pass it the `request` inside a page
`ui`.

## Usage

``` r
get_keys(x = shiny::getDefaultReactiveDomain())
```

## Arguments

- x:

  A shiny session, or the `request` object a page `ui` receives.
  Defaults to the session the code is running in.

## Value

A named list of the values matched in the page `href`, or `NULL` outside
of a brochure page.

## Examples

``` r
library(shiny)
page(
  href = "/who/:id",
  ui = function(request) {
    h1(get_keys(request)$id)
  },
  server = function(input, output, session) {
    print(get_keys())
  }
)
#> $href
#> [1] "/who/:id"
#> 
#> $ui
#> function (request) 
#> {
#>     h1(get_keys(request)$id)
#> }
#> <environment: 0x55d008018ca0>
#> 
#> $server
#> function (input, output, session) 
#> {
#>     print(get_keys())
#> }
#> <environment: 0x55d008018ca0>
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
