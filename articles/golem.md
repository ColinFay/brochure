# Using brochure with golem

[golem](https://thinkr-open.github.io/golem/) organises a Shiny
application as a package with one UI and one server, assembled in
`app_ui.R` and `app_server.R` and launched by `run_app()`. A brochure
app has no single UI and no single server: it has one of each *per
page*. The two fit together well, but the shape of the app changes, and
this article is about that shape rather than about the two functions
brochure exports — those are in
[`?golem_hook`](https://github.com/ColinFay/brochure/reference/golem_hook.md)
and
[`?new_page`](https://github.com/ColinFay/brochure/reference/new_page.md).

## What changes

| golem, as usual | golem with brochure |
|----|----|
| `app_ui.R` assembles the whole interface | gone; each page brings its own UI |
| `app_server.R` holds the whole server | gone; each page brings its own server |
| modules are pieces of one page | a module *is* a page, plus a [`page()`](https://github.com/ColinFay/brochure/reference/page.md) around it |
| `run_app()` calls [`shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html) | `run_app()` calls [`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md) |

`golem_add_external_resources()` stays, and matters more than before: it
is the one place declaring your css, javascript and favicon, and it has
to reach every page.

## A fresh app

``` r

golem::create_golem("myapp", project_hook = brochure::golem_hook)
```

The hook removes `app_ui.R` and `app_server.R`, writes a `run_app()`
built on
[`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md),
and drops in a first page, `R/mod_home.R`. It also rewrites the
[`golem::add_module()`](https://thinkr-open.github.io/golem/reference/add_module.html)
calls in `dev/02_dev.R` so they use the brochure module template — the
file you work from already does the right thing.

## Adding a page

``` r

golem::add_module(name = "contact", module_template = brochure::new_page)
```

You get a file holding three things: a module UI, a module server, and a
function wrapping both into a
[`page()`](https://github.com/ColinFay/brochure/reference/page.md):

``` r

mod_contact_ui <- function(id) {
  ns <- NS(id)
  tagList(
    h1("Hello {brochure}!")
  )
}

mod_contact_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
  })
}

contact <- function(id = "contact", href = "/contact") {
  page(
    href = href,
    ui = mod_contact_ui(id = id),
    server = function(input, output, session) {
      mod_contact_server(id = id)
    }
  )
}
```

That last function is what you add to `run_app()`. The module keeps its
namespace, so two pages may reuse the same module under different ids
and hrefs — a `mod_profile` mounted once at `/me` and once at
`/user/:id`.

## Wiring it up

``` r

run_app <- function(
  onStart = NULL,
  options = list(),
  enableBookmarking = NULL,
  ...
) {
  with_golem_options(
    app = brochureApp(
      # Injected into every page: css, javascript, favicon
      golem_add_external_resources(),
      # One entry per page
      home(),
      contact(),
      onStart = onStart,
      options = options,
      enableBookmarking = enableBookmarking
    ),
    golem_opts = list(...)
  )
}
```

`golem_add_external_resources()` goes in `...`, among the pages, because
[`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md)
injects everything there that is not a page or a redirection into all of
them. Put it inside a single
[`page()`](https://github.com/ColinFay/brochure/reference/page.md) and
only that page gets your stylesheet.

## Adapting an existing golem app

1.  delete `R/app_server.R`, and keep only
    `golem_add_external_resources()` from `R/app_ui.R`
2.  turn each screen into a file exposing a
    [`page()`](https://github.com/ColinFay/brochure/reference/page.md),
    the way
    [`new_page()`](https://github.com/ColinFay/brochure/reference/new_page.md)
    lays it out
3.  replace [`shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html)
    with
    [`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md)
    in `run_app()`, passing `golem_add_external_resources()` and then
    the pages

Step 2 is where the work is, and it is rarely mechanical. Anything the
old `app_server.R` held to pass state between screens has no equivalent:
a page cannot read another page’s reactive values, because they never
exist at the same time. That state has to move to a cookie plus a store
— see
[`vignette("cookies")`](https://github.com/ColinFay/brochure/articles/cookies.md).

## What stays golem

[`golem::get_golem_options()`](https://thinkr-open.github.io/golem/reference/get_golem_options.html),
the config file, `app_sys()`, the `dev/` scripts,
[`golem::add_dockerfile()`](https://thinkr-open.github.io/golem/reference/dockerfiles.html):
all of it works unchanged. `run_app()` is still the entry point, and the
app is still a package.

Testing changes a little: there is no single `app_server()` to drive
with
[`shiny::testServer()`](https://rdrr.io/pkg/shiny/man/testServer.html).
Test each page’s module server as you would any module, and drive the
app’s routing through its `httpHandler` with a request built by hand.
[`vignette("testing")`](https://github.com/ColinFay/brochure/articles/testing.md)
covers both.
