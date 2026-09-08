# A brochure app built to be probed, not to be pretty.
#
# Every page renders the same `#probe` block: a compact JSON saying which
# page's *server* is actually running, what keys it matched, and what cookies
# it can see. A browser test can then assert on values rather than on a
# picture, which matters here because the whole point is to catch a page
# running someone else's server.
#
# Deployed on Posit Connect under a mount, with no `basepath` set, so the
# mount has to be discovered from the request.
library(shiny)
library(brochure)

nav <- tags$ul(
  tags$li(tags$a(href = "/", "home")),
  tags$li(tags$a(href = "/one", "one")),
  tags$li(tags$a(href = "/one/two", "one/two")),
  tags$li(tags$a(href = "/one/two/three/", "one/two/three/ (trailing)")),
  tags$li(tags$a(href = "/who/colin", "who/colin")),
  tags$li(tags$a(href = "/pair/a/b", "pair/a/b")),
  tags$li(tags$a(href = "/login", "login")),
  tags$li(tags$a(href = "/logout", "logout"))
)

# The probe block, identical on every page.
probe_ui <- function() {
  tagList(
    # Forces jquery + shiny.js to load, which is how a deep page breaks when
    # relative resource urls are not rewritten.
    textInput("dummy", "input", ""),
    tags$pre(id = "probe", textOutput("probe", container = tags$code)),
    plotOutput("plot", height = "120px")
  )
}

# `parse_cookie_string()` gives a named character vector, which toJSON unboxes
# into a bare string when there is exactly one cookie. Force an object so the
# shape is the same whether there are zero, one or several.
cookies_as_object <- function() {
  cookies <- parse_cookie_string(get_cookies())
  cookies <- cookies[nzchar(names(cookies) %||% "")]
  as.list(cookies)
}

probe_server <- function(marker, plot_data) {
  function(input, output, session) {
    output$probe <- renderText({
      as.character(
        jsonlite::toJSON(
          list(
            server = marker,
            keys = get_keys(),
            cookies = cookies_as_object(),
            path = session$clientData$url_pathname
          ),
          auto_unbox = TRUE,
          null = "null"
        )
      )
    })
    output$plot <- renderPlot(plot(plot_data))
  }
}

simple_page <- function(href, marker, plot_data, extra_ui = NULL) {
  page(
    href = href,
    ui = tagList(h1(marker), nav, extra_ui, probe_ui()),
    server = probe_server(marker, plot_data)
  )
}

brochureApp(
  # --- depth: 0, 1, 2 and 3 segments, the last one visited with a slash
  page(
    href = "/",
    ui = tagList(
      h1("home"),
      nav,
      actionButton("go_deep", "server_redirect -> /one/two/three"),
      actionButton("go_key", "server_redirect -> /who/from-button"),
      actionButton("go_evil", "server_redirect -> javascript: (must be refused)"),
      probe_ui()
    ),
    server = function(input, output, session) {
      probe_server("home", mtcars)(input, output, session)
      observeEvent(input$go_deep, server_redirect("/one/two/three"))
      observeEvent(input$go_key, server_redirect("/who/from-button"))
      observeEvent(input$go_evil, {
        # Must raise rather than navigate; the message is shown on the page.
        output$probe <- renderText(
          tryCatch(
            {
              server_redirect("javascript:alert(1)")
              '{"server":"home","evil":"ACCEPTED"}'
            },
            error = function(e) '{"server":"home","evil":"REFUSED"}'
          )
        )
      })
    }
  ),
  simple_page("/one", "one", airquality),
  simple_page("/one/two", "one/two", iris),
  simple_page("/one/two/three", "one/two/three", quakes),

  # --- parameterised routes, read in the ui and in the server
  page(
    href = "/who/:id",
    ui = function(request) {
      tagList(
        h1("who"),
        nav,
        tags$p(id = "ui_key", sprintf("ui sees: %s", get_keys(request)$id)),
        probe_ui()
      )
    },
    server = probe_server("who", pressure)
  ),
  page(
    href = "/pair/:a/:b",
    ui = function(request) {
      k <- get_keys(request)
      tagList(
        h1("pair"),
        nav,
        tags$p(id = "ui_key", sprintf("ui sees: %s/%s", k$a, k$b)),
        probe_ui()
      )
    },
    server = probe_server("pair", faithful)
  ),

  # --- cookies, set and removed by page level res_handlers
  page(
    href = "/login",
    ui = tagList(h1("login"), nav, probe_ui()),
    server = probe_server("login", pressure),
    res_handlers = list(
      ~ set_cookie(.x, "BROCHURE", "logged-in", path = "/")
    )
  ),
  page(
    href = "/logout",
    ui = tagList(h1("logout"), nav, probe_ui()),
    server = probe_server("logout", pressure),
    res_handlers = list(
      ~ remove_cookie(.x, "BROCHURE", path = "/")
    )
  ),

  # --- a page level req_handler answering before any Shiny code runs
  page(
    href = "/healthcheck",
    ui = tagList(),
    req_handlers = list(
      ~ shiny::httpResponse(200, content = "OK")
    )
  ),

  # --- a page that only answers to POST
  page(
    href = "/post-only",
    method = "POST",
    ui = tagList(h1("posted")),
    req_handlers = list(
      ~ shiny::httpResponse(201, content = "CREATED")
    )
  ),

  # --- redirects, from a flat and from a deep path
  redirect(from = "/old", to = "/one/two", code = 301),
  redirect(from = "/old/deep/path", to = "/who/from-redirect", code = 302),

  # --- app level res_handler: a header that must survive the proxy
  res_handlers = list(
    function(res, req) {
      res$headers$`X-Brochure` <- "app-level"
      res
    }
  ),

  # --- extra content, injected as is into every page
  tags$script("window.__brochure_extra__ = true;"),

  content_404 = "Nothing here"
)
