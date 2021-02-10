#' Parse the cookie string
#'
#' @param cookie_string The cookie string to parse
#'
#' @return a list of cookies and values
#' @export
#'
#' @examples
#' parse_cookie_string("brochure_session=63422; brochure_cookie=3958")
parse_cookie_string <- function(cookie_string){
  if (is.null(cookie_string)) return("")
  couples <- strsplit(cookie_string, ";")[[1]]
  res <- lapply(
    couples,
    function(x) {
      #browser()
      nms <- strsplit(x, "=")[[1]]
      res <- gsub("^ +", "", nms[2])
      res <- gsub("[ ^]* +$", "", res)
      names(res) <- gsub("^ +", "", nms[1])
      names(res) <- gsub("[ ^]* +$", "", names(res))
      res
    }
  )
  unlist(res)
}



