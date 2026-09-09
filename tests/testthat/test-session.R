# A session, reduced to what brochure touches: the request it was opened with,
# and the channel `server_redirect()` writes to.
mock_session <- function(path, cookie = NULL) {
  req <- mock_req(path)
  if (!is.null(cookie)) {
    req$HTTP_COOKIE <- cookie
  }
  sent <- new.env(parent = emptyenv())
  list(
    request = req,
    sendCustomMessage = function(type, message) {
      sent[[type]] <- message
    },
    sent = sent
  )
}

test_that("a session runs the server of the page it was opened on", {
  ran <- character()
  marker <- function(name) {
    function(input, output, session) {
      ran <<- c(ran, name)
    }
  }
  app <- brochureApp(
    page(href = "/", ui = shiny::tagList(), server = marker("home")),
    page(href = "/page2", ui = shiny::tagList(), server = marker("page2"))
  )
  server <- app$serverFuncSource()

  # The websocket handshake hits `<href>/websocket/`
  server(NULL, NULL, mock_session("/page2/websocket/"))
  expect_equal(ran, "page2")

  server(NULL, NULL, mock_session("/websocket/"))
  expect_equal(ran, c("page2", "home"))
})

test_that("a session on an unknown path runs no server at all", {
  ran <- FALSE
  app <- brochureApp(
    page(
      href = "/",
      ui = shiny::tagList(),
      server = function(input, output, session) ran <<- TRUE
    )
  )
  expect_silent(
    app$serverFuncSource()(NULL, NULL, mock_session("/nope/websocket/"))
  )
  expect_false(ran)
})

test_that("get_keys reads the keys of the session's own page", {
  seen <- list()
  app <- brochureApp(
    page(
      href = "/who/:id",
      ui = shiny::tagList(),
      server = function(input, output, session) {
        seen[[length(seen) + 1]] <<- get_keys(session)
      }
    )
  )
  server <- app$serverFuncSource()

  server(NULL, NULL, mock_session("/who/alice/websocket/"))
  server(NULL, NULL, mock_session("/who/bob/websocket/"))

  expect_equal(seen[[1]]$id, "alice")
  expect_equal(seen[[2]]$id, "bob")
})

test_that("get_keys reads the keys of a request in the ui", {
  seen <- NULL
  app <- brochureApp(
    page(
      href = "/who/:id",
      ui = function(request) {
        seen <<- get_keys(request)
        shiny::tagList()
      }
    )
  )
  app$httpHandler(mock_req("/who/colin"))
  expect_equal(seen$id, "colin")
})

test_that("get_keys is empty outside a parameterised page", {
  app <- brochureApp(
    page(href = "/", ui = function(request) {
      expect_length(get_keys(request), 0)
      shiny::tagList()
    })
  )
  app$httpHandler(mock_req("/"))

  expect_null(get_keys(NULL))
})

test_that("server_redirect sends the target it was given", {
  session <- mock_session("/websocket/")

  server_redirect("/page2", session = session)
  expect_equal(session$sent$redirect, "/page2")

  server_redirect("https://example.com", session = session)
  expect_equal(session$sent$redirect, "https://example.com")

  # A refused target never reaches the browser
  expect_error(server_redirect("javascript:alert(1)", session = session))
  expect_error(server_redirect(paste0(" ", "javascript:alert(1)"), session = session))
  expect_equal(session$sent$redirect, "https://example.com")
})

test_that("get_cookies reads the header of the session's request", {
  session <- mock_session("/websocket/", cookie = "a=12; SESSION=abc")
  expect_equal(get_cookies(session), "a=12; SESSION=abc")
  expect_equal(
    parse_cookie_string(get_cookies(session)),
    c(a = "12", SESSION = "abc")
  )
  expect_equal(parse_cookie_string(NULL), "")
})

test_that("a page answering on POST still gets its server", {
  # The websocket handshake is a GET whatever method the page is served on
  ran <- FALSE
  app <- brochureApp(
    page(
      href = "/form",
      method = "POST",
      ui = shiny::tagList(),
      server = function(input, output, session) ran <<- TRUE
    )
  )
  app$serverFuncSource()(NULL, NULL, mock_session("/form/websocket/"))
  expect_true(ran)
})
