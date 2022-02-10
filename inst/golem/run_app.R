#' Run the Shiny Application
#'
#' @param ... arguments to pass to golem_opts.
#' See `?golem::get_golem_options` for more details.
#' @inheritParams brochure::brochureApp
#'
#' @export
#' @importFrom shiny shinyApp
#' @importFrom brochure brochureApp
#' @importFrom golem with_golem_options
run_app <- function(
  onStart = NULL,
  options = list(),
  enableBookmarking = NULL,
  ...
) {
  with_golem_options(
    app = brochureApp(
      # Putting the resources here
      golem_add_external_resources(),
      home(),
      onStart = onStart,
      options = options,
      enableBookmarking = enableBookmarking,
      content_404 = "Not found",
      basepath = "",
      req_handlers = list(),
      res_handlers = list(),
      wrapped = shiny::fluidPage
    ),
    golem_opts = list(...)
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @import shiny
#' @importFrom golem add_resource_path activate_js favicon bundle_resources
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )

  tags$head(
    favicon(),
    bundle_resources(
      path = app_sys("app/www"),
      app_title = "REPLACEME"
    )
    # Add here other external resources
    # for example, you can add shinyalert::useShinyalert()
  )
}
