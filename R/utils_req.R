#' @importFrom shiny httpResponse
make_404 <- function(content_404) {
  httpResponse(
    status = 404,
    content = as.character(
      content_404
    )
  )
}

# Shiny's own resource paths are served by httpuv, before R, and matched
# against the raw path. Behind a proxy that passes its mount through, that raw
# path is `/mount/jquery-3.7.1/jquery.min.js`, which is no static path at all,
# so the request reaches the app handler instead -- where the mount has just
# been stripped and Shiny's own `resourcePathHandler`, further down the chain,
# can take it.
is_resource_path <- function(path) {
  prefix <- sub("/.*$", "", sub("^/", "", path))
  nzchar(prefix) && prefix %in% names(shiny::resourcePaths())
}
