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

# `...` takes pages, redirects, and content to inject as is in every page.
# Anything else used to land in the UI of every page without a word, so a typo
# or a misplaced argument showed up as garbage on screen.
brochure_content_classes <- c(
  "brochure_page",
  "redirect",
  "shiny.tag",
  "shiny.tag.list",
  "html_dependency",
  "character"
)

# A bare list is spliced, so `brochureApp(list(page_1(), page_2()))` builds two
# pages instead of injecting the list itself into every one of them.
splice_lists <- function(content) {
  content <- lapply(
    content,
    function(x) {
      if (identical(class(x), "list")) {
        x
      } else {
        list(x)
      }
    }
  )
  content <- unlist(content, recursive = FALSE, use.names = FALSE)
  content[!vapply(content, is.null, logical(1))]
}

check_content <- function(content) {
  bad <- which(
    !vapply(
      content,
      function(x) inherits(x, brochure_content_classes),
      logical(1)
    )
  )
  if (length(bad)) {
    stop(
      sprintf(
        paste0(
          "`...` takes page()s, redirect()s, and tags or dependencies to ",
          "inject in every page.\nElement %s is a <%s>."
        ),
        bad[1],
        class(content[[bad[1]]])[1]
      ),
      call. = FALSE
    )
  }
  content
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
