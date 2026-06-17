# Navigation links use plain, app-relative hrefs ("/", "/page2", ...).
# brochure rewrites them to include the reverse-proxy mount at serve time, so
# the same code works locally and under a Posit Connect mount.
nav_links <- shiny::tags$ul(
  shiny::tags$li(
    shiny::tags$a(href = "/", "home"),
  ),
  shiny::tags$li(
    shiny::tags$a(href = "/page2", "page2"),
  ),
  shiny::tags$li(
    shiny::tags$a(href = "/contact", "contact"),
  )
)

# A simple cross-page store, keyed by a per-visitor cookie (see mod_home /
# mod_page2), in a writable temp dir.
cache_system <- cachem::cache_disk(
  file.path(tempdir(), "brochureexamples-cache")
)

# Fetch the {brochure} session cookie, generating one on first visit. Must be
# called from within a reactive context (it reads a client-side value).
fetch_brochure_cookie <- function() {
  cook <- fetch_cookies()
  if (is.null(cook$brochure_cookie)) {
    session_id <- paste0(
      sample(c(letters, 0:9), 16, replace = TRUE),
      collapse = ""
    )
    add_cookie("brochure_cookie", session_id)
    cook$brochure_cookie <- session_id
  }
  cook$brochure_cookie
}
