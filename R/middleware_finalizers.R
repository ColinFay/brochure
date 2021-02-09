add_middleware_page <- function(
  href,
  middleware
){
  ...multipage_opts$middleware_page[[href]] <- middleware
}

get_middleware_page <- function(
  href
){
  ...multipage_opts$middleware_page[[href]]
}

set_middleware_app <- function(
  middleware
){
  ...multipage_opts$middleware <- middleware
}

get_middleware_app <- function(){
  ...multipage_opts$middleware
}

add_finalizer_page <- function(
  href,
  finalizer
){
  ...multipage_opts$finalizer_page[[href]] <- finalizer
}

get_finalizer_page <- function(
  href
){
  ...multipage_opts$finalizer_page[[href]]
}

set_finalizer_page_app <- function(
  finalizer
){
  ...multipage_opts$finalizer <- finalizer
}

get_finalizer_app <- function(){
  ...multipage_opts$finalizer
}
