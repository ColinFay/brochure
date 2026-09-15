test_that("home() is a page served at /", {
  home_page <- home()
  expect_s3_class(home_page, "brochure_page")
  expect_equal(home_page$href, "/")
  golem::expect_shinytaglist(home_page$ui)
})

test_that("the home module ui works", {
  ui <- mod_home_ui(id = "test")
  golem::expect_shinytaglist(ui)
  # Check that formals have not been removed
  fmls <- formals(mod_home_ui)
  for (i in c("id")) {
    expect_true(i %in% names(fmls))
  }
})

testServer(
  mod_home_server,
  args = list(id = "home"),
  {
    ns <- session$ns
    expect_true(
      inherits(ns, "function")
    )
    expect_true(
      grepl("home", ns(""))
    )
    # Here are some examples of tests you can
    # run on your module
    # - Testing the setting of inputs
    # session$setInputs(x = 1)
    # expect_true(input$x == 1)
    # - Testing output
    # expect_true(inherits(output$tbl$html, "html"))
  }
)
