# Create a brochureApp

This function is to be used in place of
[`shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html).

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

  a list of elements to inject in the brochureApp. **IMPORTANT NOTE**
  all elements which are not of class `"brochure_*"` will be injected
  **as is** in the page. In other word, if you use a function that
  return a string, the string will be added as is to the pages. The only
  elements that should be injected on top of
  [`page()`](https://github.com/ColinFay/brochure/reference/page.md)s
  are HTML elements and/or `tagList/tags` that are invisible on screen
  (for example a `<script></script>`).

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

  The content to dislay when a 404 is sent

- basepath:

  The base path of your app. This pattern will be removed from the url,
  so that it matches the href of your
  [`page()`](https://github.com/ColinFay/brochure/reference/page.md).
  For example, it you have an app at
  `http://connect.thinkr.fr/brochure/`, and your page is names `page1`,
  use `basepath = "brochure"`

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

- wrapped:

  A UI function wrapping the Brochure UI. Default is
  [`shiny::tagList`](https://rstudio.github.io/htmltools/reference/tagList.html).

## Value

A shiny.appobj
