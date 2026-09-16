# A Brochure Page

A page is an url, a UI and a server function. Opening it starts a Shiny
session of its own, separate from any other page of the app.

## Usage

``` r
page(
  href,
  ui = tagList(),
  server = function(input, output, session) {
 },
  method = "GET",
  req_handlers = list(),
  res_handlers = list()
)
```

## Arguments

- href:

  The endpoint to serve the UI on. It can carry parameters, as in
  `"/who/:id"`, which are read back with
  [`get_keys()`](https://github.com/ColinFay/brochure/reference/get_keys.md).
  See details.

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

- method:

  The HTTP method the page answers to. Defaults to `"GET"`. A page on
  another method is unreachable if the app has a `www/` directory at its
  root: Shiny mounts it as a static path on `/`, and httpuv answers
  anything that is not a `GET` or a `HEAD` from there with a 400 before
  R sees the request. Serve those files under a prefix instead, with
  [`shiny::addResourcePath()`](https://rdrr.io/pkg/shiny/man/resourcePaths.html).

- req_handlers:

  a list of functions that can manipulate the `req` object. These
  functions should take `req` as a parameters, and return the `req`
  object (potentially modified), or an object of class httpResponse. If
  any of the req_handlers return an httpResponse, this response will be
  sent to the browser immediately, stopping any other code.

- res_handlers:

  A list of functions that can manipulate the httpResponse object before
  it is send to the browser. Each function must take a `res` and `req`
  parameter.

## Value

A `brochure_page` object, to be passed to
[`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md).

## Details

Requests are matched against hrefs by the routr package, so an href is
written the way routr writes a path:

- `"/contact"` matches that path and nothing else.

- `":name"` matches exactly one segment and captures it, so `"/who/:id"`
  matches `/who/colin` but neither `/who` nor `/who/colin/edit`. Use
  several of them if you need to: `"/pair/:a/:b"`.

- `"*"` matches whatever is left, so `"/files/*"` matches
  `/files/a/b/c`. The captured value is named `*1`.

A trailing slash never matters: `/contact` and `/contact/` are the same
page.

Pages are tried in the order you passed them to
[`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md),
and the first match wins. That holds for the session a page opens as
well, which is resolved on the path alone: the websocket handshake is a
`GET` whatever `method` the page answers on, so two pages sharing an
href run the server of the first one declared, whichever of them was
served. That matters when two hrefs can match the same url: declared as
`page("/who/me")` then `page("/who/:id")`, a request for `/who/me` gets
the first; declared the other way round, the parameterised page catches
it and the static one is never reached. Put the specific ones first.

See the routr documentation at <https://routr.data-imaginist.com/> for
the full path syntax.

## See also

[`get_keys()`](https://github.com/ColinFay/brochure/reference/get_keys.md)
to read the parameters of an href, and
[`vignette("handlers")`](https://github.com/ColinFay/brochure/articles/handlers.md)
for `req_handlers` and `res_handlers`.

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
#> <environment: 0x5648cdf23600>
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
