if (!requireNamespace("golem", quietly = TRUE)) {
  install.packages("golem")
}
options("repos" = "https://cran.rstudio.com")
golem::install_dev_deps(force = TRUE)