httpResponse <- utils::getFromNamespace("httpResponse", "shiny")

make_redirect <- function(PATH_INFO){
  dest <- ...multipage_opts$redirect[
    ...multipage_opts$redirect$from == PATH_INFO,
  ]
  httpResponse(
    status = dest$code,
    headers = list(
      Location = dest$to
    )
  )
}

make_404 <- function(content_404){
  httpResponse(
    status = 404,
    content = as.character(content_404)
  )
}
