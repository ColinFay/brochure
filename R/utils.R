rm_backslash <- function(href) {
  href <- gsub("^\\/*(.*)", "\\1", href)
  href <- gsub("(.*)\\/$", "\\1", href)
  sprintf("/%s", href)
}
