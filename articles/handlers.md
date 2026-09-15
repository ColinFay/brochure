# Request and response handlers

``` r

library(shiny)
library(brochure)
```

Between the moment a browser asks for a page and the moment it gets an
answer, brochure gives you two places to intervene. If you know
`express.js`, this is its middleware; in
[shiny](https://shiny.posit.co/) terms it is code that runs *before* any
reactive context exists.

## The order things run in

1.  the browser sends a `GET`, which R receives as a `req` object
2.  the app level `req_handlers` run, in order
3.  the request is matched against your pages
4.  the matched page’s `req_handlers` run
5.  R builds the `httpResponse` from that page’s UI
6.  the app level `res_handlers` run, then the matched page’s
7.  the response is sent

A `req_handler` takes `req` and must return it. A `res_handler` takes
`res` and `req`, and must return `res`. Both accept formulas: `.x` is
`req` for a request handler, and `res` for a response handler, where
`.y` is then `req`.

## Logging every request

``` r

log_where <- function(req) {
  message(Sys.time(), " - ", req$PATH_INFO)
  req
}

brochureApp(
  page(href = "/", ui = tagList(h1("Home"))),
  req_handlers = list(log_where)
)
```

## Answering before Shiny

A `req_handler` returning an `httpResponse` short-circuits: that
response is sent immediately, nothing else runs, and no Shiny session is
created. This is how you serve something that is not a page — a
healthcheck, a webhook receiver, a small JSON endpoint:

``` r

brochureApp(
  page(href = "/", ui = tagList(h1("Home"))),
  page(
    href = "/healthcheck",
    ui = tagList(),
    req_handlers = list(
      ~ shiny::httpResponse(200, content = "OK")
    )
  )
)
```

The page still needs a `ui`, because
[`page()`](https://github.com/ColinFay/brochure/reference/page.md)
requires an href to bind to, but it is never rendered.

Note the asymmetry: an early `httpResponse` skips the `res_handlers`
too. If you rely on a response handler to set a header on every answer,
it will not see these.

## Rejecting a request

Because a request handler can answer on its own, it can also refuse:

``` r

require_token <- function(req) {
  token <- req$HTTP_X_TOKEN
  if (is.null(token) || !identical(token, Sys.getenv("APP_TOKEN"))) {
    return(shiny::httpResponse(401, content = "Unauthorized"))
  }
  req
}

brochureApp(
  page(href = "/", ui = tagList(h1("Home"))),
  req_handlers = list(require_token)
)
```

This guards the HTTP request that serves the page. It does not guard the
websocket the page opens afterwards, so treat it as a gate on the
document, not as an authentication system.

## Changing the response

``` r

brochureApp(
  page(href = "/", ui = tagList(h1("Home"))),
  res_handlers = list(
    function(res, req) {
      res$headers$`X-Frame-Options` <- "DENY"
      res
    }
  )
)
```

App level handlers run before page level ones, so a page can override
what the app decided.

## Page level or app level

An app level handler runs for every matched page. A page level one runs
only for its own page, which is what you want for anything specific — a
cookie for the login page, a `Cache-Control` for a page that is
expensive to build.

The app level request handlers are the exception to “for every matched
page”: they run before the request is matched at all, so they see urls
that match no page, and can answer them. Everything else — the page
level handlers, and both levels of response handler — is skipped when
nothing matches, and the request gets `content_404` directly.

## Pages that answer on another method

A page answers `GET`. `method` changes that, which is how a form post or
a webhook gets a page of its own:

``` r

subscribe <- function(req) {
  fields <- shiny::parseQueryString(
    rawToChar(req$rook.input$read())
  )
  message("new subscriber: ", fields$email)
  req
}

brochureApp(
  page(
    href = "/",
    ui = tagList(
      tags$form(
        action = "/subscribe",
        method = "post",
        tags$input(type = "email", name = "email"),
        tags$input(type = "submit", value = "Subscribe")
      )
    )
  ),
  page(
    href = "/subscribe",
    method = "POST",
    ui = tagList(h1("Thanks")),
    req_handlers = list(subscribe)
  )
)
```

The method takes part in the matching, so a `GET` on `/subscribe`
matches nothing and gets `content_404`.

What was posted is yours to read: the body is on the request, as
`req$rook.input`, and brochure does not touch it. A request handler is
the place for that, since it runs before the response is built.

One thing to keep in mind: a page’s *session* is resolved on the path
alone. The websocket handshake a browser opens is a `GET` whatever
method the page was served on, so two pages declared at the same href
with different methods both run the server of the first one declared.
