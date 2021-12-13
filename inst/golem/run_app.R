#' Run the Shiny Application
#'
#' @param ... arguments to pass to golem_opts.
#' See `?golem::get_golem_options` for more details.
#' @inheritParams shiny::shinyApp
#'
#' @export
#' @importFrom shiny shinyApp
#' @importFrom golem with_golem_options
run_app <- function(onStart = NULL,
                    options = list(),
                    enableBookmarking = NULL,
                    ...) {
    with_golem_options(
        app = brochureApp(
            # Putting the resources here
            golem_add_external_resources(),
            home(),
            onStart = onStart,
            options = options,
            enableBookmarking = enableBookmarking
        ),
        golem_opts = list(...)
    )
}