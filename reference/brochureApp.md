# Create a brochureApp

This function is to be used in place of
[`shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html). It takes a
series of
[`page()`](https://github.com/ColinFay/brochure/reference/page.md)s,
each with its own url, UI and server function, and serves them from a
single Shiny application.

## Usage

``` r
brochureApp(
  ...,
  onStart = NULL,
  options = list(),
  enableBookmarking = NULL,
  content_404 = "Not found",
  basepath = "",
  req_handlers = list(),
  res_handlers = list(),
  wrapped = shiny::tagList
)
```

## Arguments

- ...:

  The
  [`page()`](https://github.com/ColinFay/brochure/reference/page.md)s
  and
  [`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)s
  of the app, plus anything to inject **as is** into every page: tags,
  tag lists, html dependencies and strings. That is how you add
  something to all your pages at once, a `<script>` or the resources of
  a `{golem}` app for example. Note that a string is injected too, so a
  stray value ends up rendered on every page. Anything else is an error
  naming the element it cannot use. A bare list is spliced, so
  `brochureApp(list(page_1(), page_2()))` builds two pages rather than
  injecting the list into each of them.

- onStart:

  A function that will be called before the app is actually run. This is
  only needed for `shinyAppObj`, since in the `shinyAppDir` case, a
  `global.R` file can be used for this purpose.

- options:

  Named options that should be passed to the `runApp` call (these can be
  any of the following: "port", "launch.browser", "host", "quiet",
  "display.mode" and "test.mode"). You can also specify `width` and
  `height` parameters which provide a hint to the embedding environment
  about the ideal height/width for the app.

- enableBookmarking:

  Can be one of `"url"`, `"server"`, or `"disable"`. The default value,
  `NULL`, will respect the setting from any previous calls to
  [`enableBookmarking()`](https://rdrr.io/pkg/shiny/man/enableBookmarking.html).
  See
  [`enableBookmarking()`](https://rdrr.io/pkg/shiny/man/enableBookmarking.html)
  for more information on bookmarking your app.

- content_404:

  The content served when no
  [`page()`](https://github.com/ColinFay/brochure/reference/page.md)
  matches the url.

- basepath:

  The path your app is served under by a reverse proxy. It is removed
  from the incoming url, so that what is left matches the href of your
  [`page()`](https://github.com/ColinFay/brochure/reference/page.md),
  and it is prepended to the urls the app emits. For example, if your
  app is served at `http://connect.thinkr.fr/brochure/` and your page is
  named `page1`, use `basepath = "brochure"`.

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

- wrapped:

  A UI function wrapping the Brochure UI. Default is
  [`shiny::tagList`](https://rstudio.github.io/htmltools/reference/tagList.html).

## Value

A shiny.appobj

## Details

Behind a reverse proxy, `basepath` tells the app where it is mounted: it
is removed from the incoming path, and prepended to the urls the app
emits. On Posit Connect the mount is picked up on its own, from the
`RStudio-Connect-App-Base-URL` header, and `basepath` is not needed.
That header is not part of any published contract, so set `basepath` if
you want the behaviour pinned. Brochure also injects a small script
registering the handler
[`server_redirect()`](https://github.com/ColinFay/brochure/reference/server_redirect.md)
talks to, which prefixes internal targets with the mount.

## See also

[`page()`](https://github.com/ColinFay/brochure/reference/page.md) to
declare a page,
[`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)
to answer an url with a redirection, and
[`vignette("deployment")`](https://github.com/ColinFay/brochure/articles/deployment.md)
to serve the app under a prefix.

## Examples

``` r
library(shiny)

app <- brochureApp(
  page(
    href = "/",
    ui = tagList(h1("Home")),
    server = function(input, output, session) {}
  ),
  page(
    href = "/contact",
    ui = tagList(h1("Contact"))
  ),
  redirect(from = "/index.html", to = "/")
)

# Then run it as you would any Shiny app:
if (interactive()) {
  shiny::runApp(app)
}
```
