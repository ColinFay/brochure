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

test_that("a bare list of pages is spliced", {
  app <- brochureApp(
    list(
      page(href = "/", ui = shiny::tagList(shiny::h1("home"))),
      page(href = "/page2", ui = shiny::tagList(shiny::h1("second")))
    )
  )

  expect_match(app$httpHandler(mock_req("/"))$content, "home")
  expect_match(app$httpHandler(mock_req("/page2"))$content, "second")
})

test_that("`...` rejects what it cannot use", {
  ok <- page(href = "/", ui = shiny::tagList())

  expect_error(brochureApp(ok, mtcars), "data.frame")
  expect_error(brochureApp(ok, 1:3), "integer")
  expect_error(brochureApp(ok, function(x) x), "function")

  # NULL is dropped, tags and dependencies go through
  expect_s3_class(brochureApp(ok, NULL), "shiny.appobj")
  expect_s3_class(brochureApp(ok, shiny::tags$script("x")), "shiny.appobj")
})

test_that("basepath is stripped from the incoming path", {
  app <- brochureApp(
    page(href = "/", ui = shiny::tagList(shiny::h1("home"))),
    page(href = "/page2", ui = shiny::tagList(shiny::h1("second"))),
    basepath = "brochure"
  )

  # A proxy that passes the mount through
  expect_match(app$httpHandler(mock_req("/brochure/page2"))$content, "second")
  expect_match(app$httpHandler(mock_req("/brochure"))$content, "home")
  # ... and one that strips it, like Posit Connect
  expect_match(app$httpHandler(mock_req("/page2"))$content, "second")

  expect_equal(app$httpHandler(mock_req("/nope"))$status, 404)
})

test_that("basepath prefixes the emitted urls", {
  app <- brochureApp(
    page(href = "/", ui = shiny::tagList()),
    basepath = "brochure"
  )

  content <- app$httpHandler(mock_req("/brochure"))$content
  expect_match(content, 'src="/brochure/shiny-javascript')
})

test_that("redirect refuses a target it would write into a header", {
  # `to` lands in a Location header, where a CRLF would append one of its own
  expect_error(redirect(from = "/x", to = paste0("/y", "\r\n", "Set-Cookie: a=1")))
  expect_error(redirect(from = "/x", to = "javascript:alert(1)"))
  expect_error(redirect(from = "/x", to = paste0(" ", "javascript:alert(1)")))

  expect_s3_class(redirect(from = "/x", to = "/y"), "redirect")
  expect_s3_class(redirect(from = "/x", to = "https://example.com"), "redirect")
})

test_that("an internal redirect stays under the mount", {
  app <- brochureApp(
    page(href = "/page2", ui = shiny::tagList()),
    redirect(from = "/old", to = "/page2"),
    redirect(from = "/away", to = "https://example.com"),
    basepath = "myapp"
  )

  expect_equal(
    app$httpHandler(mock_req("/myapp/old"))$headers$Location,
    "/myapp/page2"
  )
  # An absolute target belongs to whoever wrote it
  expect_equal(
    app$httpHandler(mock_req("/myapp/away"))$headers$Location,
    "https://example.com"
  )

  flat <- brochureApp(
    page(href = "/page2", ui = shiny::tagList()),
    redirect(from = "/old", to = "/page2")
  )
  expect_equal(flat$httpHandler(mock_req("/old"))$headers$Location, "/page2")
})

test_that("resource urls go under the mount, navigation links keep their shape", {
  app <- brochureApp(
    page(href = "/", ui = shiny::tagList(
      shiny::tags$a(href = "contact", "relative link"),
      shiny::tags$a(href = "/contact", "absolute link"),
      shiny::tags$a(href = "https://example.com", "external link"),
      shiny::tags$img(src = "logo.png"),
      shiny::tags$img(src = "/img.png"),
      shiny::tags$img(src = "https://example.com/x.png")
    )),
    basepath = "myapp"
  )
  content <- app$httpHandler(mock_req("/myapp/"))$content

  # Both kinds of resource url end up under the mount
  expect_match(content, 'src="/myapp/logo.png"', fixed = TRUE)
  expect_match(content, 'src="/myapp/img.png"', fixed = TRUE)
  # A root absolute link is moved under the mount, a relative one is left alone
  expect_match(content, 'href="/myapp/contact"', fixed = TRUE)
  expect_match(content, 'href="contact"', fixed = TRUE)
  # Nothing pointing elsewhere is touched
  expect_match(content, 'href="https://example.com"', fixed = TRUE)
  expect_match(content, 'src="https://example.com/x.png"', fixed = TRUE)
})
