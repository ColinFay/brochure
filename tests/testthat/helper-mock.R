# A Rook environment, as httpuv hands one to the app, small enough to build by
# hand: `rook.version` is what makes routr accept it as a request.
mock_req <- function(path, method = "GET") {
  req <- new.env(parent = emptyenv())
  req$REQUEST_METHOD <- method
  req$PATH_INFO <- path
  req$QUERY_STRING <- ""
  req$SCRIPT_NAME <- ""
  req$SERVER_NAME <- "127.0.0.1"
  req$SERVER_PORT <- "3000"
  req$HTTP_HOST <- "127.0.0.1:3000"
  req$rook.url_scheme <- "http"
  req$rook.version <- "1.1-0"
  req
}
