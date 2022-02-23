with_class <- function(res, pop_class) {
  class(res) <- c(
    pop_class,
    class(res)
  )
  res
}

check_redirect_code <- function(code) {
  attempt::stop_if(
    code,
    ~ !.x %in% c(
      301:308,
      310
    ),
    sprintf(
      "Redirect code should be one of %s.",
      paste(
        c(
          301:308,
          310
        ),
        collapse = " "
      )
    )
  )
}

extract <- function(content, class) {
  vapply(
    content,
    function(x) {
      inherits(x, class)
    },
    logical(1)
  )
}

build_redirect <- function(redirect) {
  do.call(
    rbind,
    lapply(
      redirect,
      function(x) {
        data.frame(
          from = x$from,
          to = x$to,
          code = x$code
        )
      }
    )
  )
}
