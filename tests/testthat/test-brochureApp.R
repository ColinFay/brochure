# A Rook environment, as httpuv hands one to the app, small enough to build by
# hand: `rook.version` is what makes routr accept it as a request.
mock_req <- function(path, method = "GET") {
  req <- new.env(parent = emptyenv())
  req$REQUEST_METHOD <- method
  req$PATH_INFO <- path
  req$QUERY_STRING <- ""
  req$SCRIPT_NAME <- ""
  req$SERVER_NAME <- "127.0.0.1"
  req$SERVER_PORT <- "3000"
  req$HTTP_HOST <- "127.0.0.1:3000"
  req$rook.url_scheme <- "http"
  req$rook.version <- "1.1-0"
  req
}

test_that("a matched page is served", {
  app <- brochureApp(
    page(href = "/", ui = shiny::tagList(shiny::h1("home"))),
    page(href = "/page2", ui = shiny::tagList(shiny::h1("second")))
  )

  res <- app$httpHandler(mock_req("/"))
  expect_equal(res$status, 200)
  expect_match(res$content, "home")

  res <- app$httpHandler(mock_req("/page2"))
  expect_equal(res$status, 200)
  expect_match(res$content, "second")
})

test_that("an unmatched path gets the 404 content", {
  app <- brochureApp(
    page(href = "/", ui = shiny::tagList(shiny::h1("home"))),
    content_404 = "Nothing here"
  )

  res <- app$httpHandler(mock_req("/nope"))
  expect_equal(res$status, 404)
  expect_equal(res$content, "Nothing here")
})

test_that("a redirect answers with its code and Location", {
  app <- brochureApp(
    page(href = "/", ui = shiny::tagList()),
    redirect(from = "/old", to = "/", code = 302)
  )

  res <- app$httpHandler(mock_req("/old"))
  expect_equal(res$status, 302)
  expect_equal(res$headers$Location, "/")
})

test_that("app handlers run, and an httpResponse from one short-circuits", {
  seen <- character()
  app <- brochureApp(
    page(href = "/", ui = shiny::tagList(shiny::h1("home"))),
    req_handlers = list(function(req) {
      seen <<- c(seen, req$PATH_INFO)
      req
    }),
    res_handlers = list(~ {
      .x$headers$`X-App` <- "yes"
      .x
    })
  )

  res <- app$httpHandler(mock_req("/"))
  expect_equal(seen, "/")
  expect_equal(res$headers$`X-App`, "yes")

  stopping <- brochureApp(
    page(href = "/", ui = shiny::tagList()),
    req_handlers = list(~ shiny::httpResponse(200, content = "OK"))
  )
  res <- stopping$httpHandler(mock_req("/"))
  expect_equal(res$content, "OK")
})

test_that("page handlers run for their page only", {
  app <- brochureApp(
    page(href = "/", ui = shiny::tagList(shiny::h1("home"))),
    page(
      href = "/healthcheck",
      ui = shiny::tagList(),
      req_handlers = list(~ shiny::httpResponse(200, content = "OK"))
    ),
    page(
      href = "/login",
      ui = shiny::tagList(),
      res_handlers = list(~ set_cookie(.x, "BROCHURECOOKIE", 12))
    )
  )

  expect_equal(app$httpHandler(mock_req("/healthcheck"))$content, "OK")
  expect_match(
    app$httpHandler(mock_req("/login"))$headers$`Set-Cookie`,
    "^BROCHURECOOKIE=12;"
  )
  expect_null(app$httpHandler(mock_req("/"))$headers$`Set-Cookie`)
})

test_that("app level res handlers run before the page ones", {
  app <- brochureApp(
    page(
      href = "/",
      ui = shiny::tagList(),
      res_handlers = list(~ {
        .x$headers$`X-Order` <- paste(.x$headers$`X-Order`, "page")
        .x
      })
    ),
    res_handlers = list(~ {
      .x$headers$`X-Order` <- "app"
      .x
    })
  )

  expect_equal(app$httpHandler(mock_req("/"))$headers$`X-Order`, "app page")
})

test_that("two apps in one process keep their own handlers", {
  tagged <- function(tag) {
    brochureApp(
      page(href = "/", ui = shiny::tagList()),
      res_handlers = list(function(res, req) {
        res$headers$`X-App` <- tag
        res
      })
    )
  }
  a <- tagged("A")
  b <- tagged("B")

  expect_equal(a$httpHandler(mock_req("/"))$headers$`X-App`, "A")
  expect_equal(b$httpHandler(mock_req("/"))$headers$`X-App`, "B")
  expect_equal(a$httpHandler(mock_req("/"))$headers$`X-App`, "A")
})

test_that("relative resource URLs are made absolute", {
  app <- brochureApp(
    page(href = "/who/:id", ui = shiny::tagList(shiny::h1("who")))
  )

  # Shiny emits its dependencies relative; on a nested page they would resolve
  # against "/who/" and 404.
  content <- app$httpHandler(mock_req("/who/colin"))$content
  expect_match(content, 'src="/shiny-javascript')
  expect_no_match(content, 'src="shiny-javascript')
})

test_that("the client bootstrap is injected once", {
  app <- brochureApp(page(href = "/", ui = shiny::tagList()))
  content <- app$httpHandler(mock_req("/"))$content
  expect_equal(
    length(gregexpr("__brochure_client__", content, fixed = TRUE)[[1]]),
    1
  )
})
