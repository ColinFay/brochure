basepath <- "brochure"

nav_links <- shiny::tags$ul(
  shiny::tags$li(
    shiny::tags$a(href = sprintf("/%s/", basepath), "home"),
  ),
  shiny::tags$li(
    shiny::tags$a(href = sprintf("/%s/page2", basepath), "page2"),
  ),
  shiny::tags$li(
    shiny::tags$a(href = sprintf("/%s/contact", basepath), "contact"),
  )
)

cache_system <- cachem::cache_disk("inst/cache")
