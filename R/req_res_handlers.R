#' @importFrom rlang as_function
add_req_handlers_page <- function(
  href,
  req_handlers
) {
  req_handlers <- lapply(req_handlers, as_function)
  ...multipage_opts$req_handlers_page[[href]] <- req_handlers
}

get_req_handlers_page <- function(href) {
  ...multipage_opts$req_handlers_page[[href]]
}

set_req_handlers_app <- function(req_handlers) {
  ...multipage_opts$req_handlers <- req_handlers
}

get_req_handlers_app <- function() {
  ...multipage_opts$req_handlers
}

#' @importFrom rlang as_function
add_res_handlers_page <- function(
  href,
  res_handlers
) {
  res_handlers <- lapply(
    res_handlers,
    as_function
  )
  ...multipage_opts$res_handlers_page[[href]] <- res_handlers
}

get_res_handlers_page <- function(href) {
  ...multipage_opts$res_handlers_page[[href]]
}

set_res_handlers_page <- function(res_handlers) {
  ...multipage_opts$res_handlers <- res_handlers
}

get_res_handlers_app <- function() {
  ...multipage_opts$res_handlers
}
