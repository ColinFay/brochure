# Designing a multipage app

``` r

library(shiny)
library(brochure)
```

Everything in brochure follows from one sentence: **a page is a Shiny
session, and two sessions never meet.**

Opening `/contact` does not hide `/` and show something else. It closes
the first session and opens a second one, which loads its own UI and
runs its own server. Nothing computed on the first page is there when
the second starts.

That is not a limitation to work around. It is the trade: you get urls
that mean something, and you give up the shared reactive graph that a
single page app leans on. This article is about what that costs and how
the usual patterns translate.

## Coming from a single page app

| Single page Shiny | brochure |
|----|----|
| [`tabsetPanel()`](https://rdrr.io/pkg/shiny/man/tabsetPanel.html) / [`navbarPage()`](https://rdrr.io/pkg/shiny/man/navbarPage.html) | one [`page()`](https://github.com/ColinFay/brochure/reference/page.md) per tab |
| [`conditionalPanel()`](https://rdrr.io/pkg/shiny/man/conditionalPanel.html) on a “screen” input | one [`page()`](https://github.com/ColinFay/brochure/reference/page.md) per screen |
| [`updateTabsetPanel()`](https://rdrr.io/pkg/shiny/man/updateTabsetPanel.html) to move around | a link, or [`server_redirect()`](https://github.com/ColinFay/brochure/reference/server_redirect.md) |
| [`renderUI()`](https://rdrr.io/pkg/shiny/man/renderUI.html) picking the screen | the url picks the page |
| a navbar written once in the ui | `wrapped`, or a tag list in `...` |
| [`reactiveValues()`](https://rdrr.io/pkg/shiny/man/reactiveValues.html) shared by the screens | a cookie plus a store |
| [`moduleServer()`](https://rdrr.io/pkg/shiny/man/moduleServer.html) per screen | the same modules, one per page |

Modules survive the move unchanged, which is most of the work saved.
What does not survive is whatever passed values *between* them.

## Navigation is a link

``` r

tags$a(href = "/contact", "Contact")
```

No router to configure, no observer, no
[`updateTabsetPanel()`](https://rdrr.io/pkg/shiny/man/updateTabsetPanel.html).
The browser asks the server for that url, and the back button, the
middle click and “open in a new tab” all work because nothing was faked.

[`server_redirect()`](https://github.com/ColinFay/brochure/reference/server_redirect.md)
is for the other case: navigating as the *result* of something, once a
form is submitted or a login accepted.

``` r

page(
  href = "/login",
  ui = tagList(passwordInput("pw", "Password"), actionButton("go", "Log in")),
  server = function(input, output, session) {
    observeEvent(input$go, {
      if (identical(input$pw, Sys.getenv("APP_PASSWORD"))) {
        server_redirect("/")
      }
    })
  }
)
```

## What every page shares

Three things reach every page, and they are the three places to put
anything common — see
[`vignette("brochure")`](https://github.com/ColinFay/brochure/articles/brochure.md)
for the mechanics:

- tags and dependencies passed to
  [`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md)
  in `...`: css, favicon, a `<script>`
- `wrapped`, a function applied to each page’s UI: the layout, a navbar,
  a footer
- code evaluated when the app is assembled

That last one deserves care.
[`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md)
runs once, when the app starts, not once per visitor:

``` r

store <- cachem::cache_disk()

brochureApp(
  home(),
  login()
)
```

`store` is built once and shared by everyone, which is exactly what you
want for a cache, a database pool, a lookup table read from disk. It is
exactly what you do not want for anything belonging to one visitor: an
identifier minted there is handed to every one of them.

## Where state goes

There are two places, and the difference between them is who chooses the
value.

**The url**, when the visitor does. A parameterised href makes the state
part of the address, which means it can be linked to, bookmarked and
shared:

``` r

page(
  href = "/product/:sku",
  ui = function(request) {
    mod_product_ui("product")
  },
  server = function(input, output, session) {
    mod_product_server("product", sku = get_keys()$sku)
  }
)
```

**A cookie plus a store**, when it is yours to decide. The cookie names
a session; the data lives server side, keyed by that name.
[`vignette("cookies")`](https://github.com/ColinFay/brochure/articles/cookies.md)
covers it, including the two mistakes that are silent when made.

What does not work, and is worth naming because it is the reflex you are
bringing with you: a
[`reactiveValues()`](https://rdrr.io/pkg/shiny/man/reactiveValues.html)
at app scope. It is a single object, shared by every visitor and every
page, and it is not reactive across sessions. The same goes for
assigning into the global environment.

## What a navigation costs

Each one is a full page load: a new http request, a new websocket, the
UI built again, and every
[`renderPlot()`](https://rdrr.io/pkg/shiny/man/renderPlot.html) on the
arriving page computed from scratch. That is a fraction of a second on a
page that reads a small data frame, and several seconds on one that
queries a database on startup.

So the data a page needs is fetched again each time it is opened, and
caching it at app scope is what makes that cheap:

``` r

# Read once, shared by every session
reference <- readRDS(app_sys("data/reference.rds"))

# Or memoised, if it has to be fetched
get_sales <- memoise::memoise(function(region) {
  DBI::dbGetQuery(pool, "select * from sales where region = ?", list(region))
})
```

The upside of the same design: a session loads one page’s worth of UI
and runs one page’s worth of server. A visitor reading the contact page
is not holding the dashboard’s reactive graph open.

## Several visitors at once

A session is one visitor on one page: two people reading `/dashboard`
are two sessions, and one person with `/dashboard` and `/admin` open in
two tabs is two sessions as well. That is Shiny’s usual arrangement, and
brochure does not change it.

What it does not change either is that all of them live in one R
process. Pages are not processes: a page that blocks holds up every
other page and every other visitor. On a two page app where `/slow`
takes five seconds to render, `/fast` answers in 0.2s on its own and in
4.8s when it is opened while `/slow` is rendering.

So the reasons to reach for
[promises](https://rstudio.github.io/promises/) and
[future](https://future.futureverse.org) in a Shiny app are the same
ones here, and splitting an app into pages is not one of them. One thing
to keep in mind when you do: a navigation ends the session, so a future
still running when the visitor leaves has nowhere left to deliver.

## When not to reach for brochure

An app whose screens genuinely interact — a filter in a sidebar feeding
six outputs, a selection in one tab driving a plot in another — is one
page. Making it several means inventing a way to carry the shared state
across, and the result is a worse version of what
[`tabsetPanel()`](https://rdrr.io/pkg/shiny/man/tabsetPanel.html) gave
you for free.

Brochure earns its place when the parts of your app are *separate*: a
landing page, a login, a dashboard, an admin panel, a public report at a
url you can send to someone. Different urls because they are different
things — not because the app happens to have several screens.

## Where to go next

- [`vignette("brochure")`](https://github.com/ColinFay/brochure/articles/brochure.md)
  — pages, routing, and what reaches every page
- [`vignette("cookies")`](https://github.com/ColinFay/brochure/articles/cookies.md)
  — the cookie and store pattern, in full
- [`vignette("testing")`](https://github.com/ColinFay/brochure/articles/testing.md)
  — testing the routing without a browser
- [`vignette("golem")`](https://github.com/ColinFay/brochure/articles/golem.md)
  — the same app, as a package
