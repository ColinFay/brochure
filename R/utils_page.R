with_class <- function(res, pop_class) {
  class(res) <- c(
    pop_class,
    class(res)
  )
  res
}

# 304 revalidates a cache, 305 is deprecated, 306 and 310 were never assigned:
# none of them make a browser follow a Location.
redirect_codes <- c(301, 302, 303, 307, 308)

check_redirect_code <- function(code) {
  attempt::stop_if_not(
    code,
    ~ length(.x) == 1 && .x %in% redirect_codes,
    sprintf(
      "Redirect code should be one of %s.",
      paste(redirect_codes, collapse = " ")
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

# Shiny turns the name and version of an html dependency into its url prefix,
# and the last `addResourcePath()` for a prefix wins. Two pages carrying two
# `bslib::bs_theme()`s both ship a dependency named "bootstrap" at the same
# version, pointing at two different compiled directories: they share one url,
# and the browser serves whichever css it has cached under it. Bumping the
# version of every source directory but the first gives each one its own
# prefix. `resolveDependencies()` keeps the highest version of a name, so the
# copy returned here is the one rendered.
unclash_dep <- function(dep, seen) {
  if (is.null(dep$src$file)) {
    return(NULL)
  }
  prefix <- paste0(dep$name, "-", dep$version)
  files <- seen[[prefix]]
  index <- match(dep$src$file, files)
  if (is.na(index)) {
    index <- length(files) + 1L
    seen[[prefix]] <- c(files, dep$src$file)
  }
  if (index == 1L) {
    return(NULL)
  }
  dep$version <- paste0(dep$version, ".", index)
  dep
}

unclash_deps <- function(ui, seen) {
  extra <- purrr::compact(
    lapply(
      htmltools::findDependencies(ui),
      unclash_dep,
      seen = seen
    )
  )
  if (!length(extra)) {
    return(ui)
  }
  htmltools::attachDependencies(ui, extra, append = TRUE)
}
