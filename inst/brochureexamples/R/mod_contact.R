#' Contact page ("/contact")
#'
#' A static page (no server needed).
#'
#' @import shiny
#' @import brochure
#' @noRd
contact <- function() {
  page(
    href = "/contact",
    ui = tagList(
      h1("Contact us"),
      nav_links,
      tags$ul(
        tags$li("Here"),
        tags$li("There")
      )
    )
  )
}
