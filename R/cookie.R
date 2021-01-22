#' Get the Brochure Cookie
#'
#' @param session A shiny sessino object
#'
#' @return A string with the cookie, or NA if there is no cookie.
#' @export
get_brochure_cookie <- function(
  session = shiny::getDefaultReactiveDomain()
  ){
  parse_cookie(session$request$HTTP_COOKIE)["brochure_session"]

}

parse_cookie <- function(txt){
  if (is.null(txt)) return("")
  couples <- strsplit(txt, ";")[[1]]
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


local_cookie <- function(){
  list(
    get_all = function(name){
      cookie_file <- system.file("cookies.txt", package = "brochure")
      if (file.exists(cookie_file)){
        readLines(
          cookie_file
        )
      } else {
        return(c(""))
      }
    },
    add_cookie = function(){
      all <- local_cookie()$get_all()
      is_valid <- FALSE
      while (!is_valid) {
        new_cookie <- digest::digest(
          c(sample(1e5), Sys.time())
        )
        if (!new_cookie %in% all){
          is_valid <- TRUE
          write(
            new_cookie,
            # bypass the non existance of the file when first cookie is written
            file.path(system.file( package = "brochure"), "cookies.txt"),
            append = TRUE
          )
        }
      }
      new_cookie
    },
    delete_cookie = function(which){
      all <- local_cookie()$get_all()
      all <- all[all != which]
      write(
        all,
        system.file("cookies.txt", package = "brochure")
      )
    },
    is_valid = function(which){
      which %in% local_cookie()$get_all()
    }
  )
}
