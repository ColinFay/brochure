test_that("playwright tests are working", {
  skip_on_cran()
  skip_if_not(
    nzchar(Sys.which("npx")),
    "npx is not available"
  )
  skip_if_not(
    dir.exists("../playwright/node_modules"),
    "the playwright suite is not installed"
  )
  # The suite boots `inst/simple` from the package root, so it only runs from a
  # source tree -- not from the copy `covr` or `R CMD check` works in.
  skip_if_not(
    dir.exists("../../inst/simple"),
    "not running from the package sources"
  )

  old <- setwd("../playwright")
  on.exit(setwd(old))

  res <- system2(
    "npx",
    c(
      "playwright",
      "test"
    )
  )
  # Exit with code 0 means that the tests passed
  expect_equal(res, 0)
})
