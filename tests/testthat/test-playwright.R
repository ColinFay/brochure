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
