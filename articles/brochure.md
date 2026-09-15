# Getting started with brochure

A [shiny](https://shiny.posit.co/) app usually lives at a single url,
and everything you show is a matter of hiding and showing pieces of one
page. [brochure](https://github.com/colinfay/brochure) takes the other
road: an app serves several endpoints, and each of them is its own page,
with its own UI and its own server function.

``` r

library(shiny)
library(brochure)
```

## A page

[`page()`](https://github.com/ColinFay/brochure/reference/page.md) binds
an href to a UI and a server function. The server is optional: a page
that only shows static content does not need one.

``` r

home <- function() {
  page(
    href = "/",
    ui = tagList(
      h1("Home"),
      plotOutput("plot")
    ),
    server = function(input, output, session) {
      output$plot <- renderPlot(plot(mtcars))
    }
  )
}

contact <- function() {
  page(
    href = "/contact",
    ui = tagList(
      h1("Contact"),
      tags$p("here@example.com")
    )
  )
}
```

## An app

[`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md)
replaces [`shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html),
and takes the pages:

``` r

brochureApp(
  home(),
  contact()
)
```

Navigating between pages is done with plain links —
`tags$a(href = "/contact")`. There is no router to configure on the
client: a link is a real navigation, and the browser asks the server for
that url.

Which brings the one thing to keep in mind: **every page is a new Shiny
session**. Nothing you compute on `/` is available on `/contact`. That
is the point rather than a limitation — it forces the data flowing
between pages to be explicit — but it means state has to live somewhere
shared: a cookie, a database, a disk cache.

## Something on every page

Anything passed to
[`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md)
that is not a
[`page()`](https://github.com/ColinFay/brochure/reference/page.md) or a
[`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)
is injected as it is into every page. That is where a stylesheet, a
favicon or a `<script>` goes:

``` r

brochureApp(
  tags$head(
    tags$link(rel = "stylesheet", href = "/www/custom.css"),
    tags$link(rel = "icon", href = "/www/favicon.ico")
  ),
  home(),
  contact()
)
```

Tags, tag lists, html dependencies and strings are accepted — a string
too, so a stray value ends up rendered on every page. Anything else is
an error naming the element it could not use.

`wrapped` is the other half of “on every page”: a function applied to
the UI of each page, which is where a common layout goes. Pass it
`fluidPage` and every page becomes one, Bootstrap and all — the layout a
single page app gets from its own
[`fluidPage()`](https://rdrr.io/pkg/shiny/man/fluidPage.html) call:

``` r

brochureApp(
  home(),
  contact(),
  wrapped = fluidPage
)
```

Any function taking the ui and returning a ui works, so a navbar shared
by the whole app is written once:

``` r

with_nav <- function(ui) {
  fluidPage(
    tags$nav(
      tags$a(href = "/", "Home"),
      tags$a(href = "/contact", "Contact")
    ),
    ui
  )
}

brochureApp(home(), contact(), wrapped = with_nav)
```

## How a url finds its page

Matching a request to a page is done by the
[`{routr}`](https://routr.data-imaginist.com/) package, and an href is
written the way routr writes a path:

| href          | matches                 | does not match            |
|---------------|-------------------------|---------------------------|
| `/contact`    | `/contact`, `/contact/` | anything else             |
| `/who/:id`    | `/who/colin`            | `/who`, `/who/colin/edit` |
| `/pair/:a/:b` | `/pair/x/y`             | `/pair/x`                 |
| `/files/*`    | `/files/a/b/c`          | `/files/`                 |

Three rules cover it:

- `:name` captures **exactly one** segment. `/who/:id` will not match
  `/who`, so if you want that page too, declare it separately.
- `*` captures whatever is left, however many segments that is.
- A trailing slash never makes a difference.

**Pages are tried in the order you pass them, and the first match
wins.** When two hrefs can match the same url, the specific one has to
come first:

``` r

brochureApp(
  page(href = "/who/me", ui = tagList(h1("It's you"))),
  page(href = "/who/:id", ui = tagList(h1("Someone else")))
)
```

Swap those two lines and `/who/:id` catches `/who/me` first: the page
you wrote for it becomes unreachable, silently.

## When no page matches

A url matching none of your pages gets a 404, whose body is
`content_404`:

``` r

brochureApp(
  home(),
  contact(),
  content_404 = tagList(
    h1("This page does not exist"),
    tags$a(href = "/", "Back home")
  )
)
```

It is served as it is written, and unlike a page it is not rewritten for
`basepath`. Under a prefix, `href = "/"` therefore points at the root of
the domain rather than at your home page: write the prefix in yourself,
`href = "/myapp/"`.

## Reading the parameters

What `:name` and `*` captured is read with
[`get_keys()`](https://github.com/ColinFay/brochure/reference/get_keys.md):
with no argument inside the server, and with the `request` the ui
receives inside the ui.

``` r

brochureApp(
  page(
    href = "/who/:id",
    ui = function(request) {
      tagList(
        h1(sprintf("Hello %s", get_keys(request)$id)),
        verbatimTextOutput("from_server")
      )
    },
    server = function(input, output, session) {
      output$from_server <- renderText(get_keys()$id)
    }
  )
)
```

`/who/colin` and `/who/fay` are two sessions of the same page, each with
its own `id`. A `*` lands in a key named `*1`, so `/files/*` matched
against `/files/a/b/c` gives `get_keys()[["*1"]]` equal to `"a/b/c"`.

## Redirections

``` r

brochureApp(
  home(),
  redirect(from = "/index.html", to = "/")
)
```

[`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)
answers at the http level, before any Shiny code runs. From inside a
server, `server_redirect("/contact")` sends the browser to another page.

## Middleware

Every page, and the app itself, takes `req_handlers` and `res_handlers`:
lists of functions run on the request before the response is built, and
on the response before it is sent. App level handlers run first, then
those of the matched page.

A `req_handler` returning an `httpResponse` short-circuits everything
else, which is how you serve something that is not a page at all:

``` r

brochureApp(
  home(),
  page(
    href = "/healthcheck",
    ui = tagList(),
    req_handlers = list(
      ~ shiny::httpResponse(200, content = "OK")
    )
  )
)
```

A `res_handler` is where you set a cookie:

``` r

page(
  href = "/login",
  ui = tagList(h1("Logged in")),
  res_handlers = list(
    ~ set_cookie(.x, "SESSION", "abc123")
  )
)
```

Read it back from the server with
[`get_cookies()`](https://github.com/ColinFay/brochure/reference/cookies-server-side.md)
and
[`parse_cookie_string()`](https://github.com/ColinFay/brochure/reference/cookies-server-side.md).

## Behind a reverse proxy

If the app is not served at the root of its domain, tell it where it is
mounted with `basepath`:

``` r

brochureApp(
  home(),
  basepath = "myapp"
)
```

The prefix is removed from incoming urls, so it keeps matching your
[`page()`](https://github.com/ColinFay/brochure/reference/page.md)
hrefs, and prepended to the urls the app emits. On Posit Connect the
mount is picked up on its own and `basepath` is not needed.

## What’s next

- [`vignette("handlers")`](https://github.com/ColinFay/brochure/articles/handlers.md)
  — running code before and after a page is built, and answering a
  request without Shiny at all.
- [`vignette("cookies")`](https://github.com/ColinFay/brochure/articles/cookies.md)
  — setting and reading cookies, and carrying a session from one page to
  the next.
- [`vignette("deployment")`](https://github.com/ColinFay/brochure/articles/deployment.md)
  — serving the app under a prefix.
- [`vignette("design")`](https://github.com/ColinFay/brochure/articles/design.md)
  — what changes when an app is several pages, and where state goes once
  no session is shared.
- [`vignette("testing")`](https://github.com/ColinFay/brochure/articles/testing.md)
  — testing the routing, the pages and the app.
- [`vignette("golem")`](https://github.com/ColinFay/brochure/articles/golem.md)
  — building a brochure app as a golem package.
