# Generated by fusen: do not edit by hand

test_that("golem_hook works", {
  skip_if_not_installed("golem")
  old <- setwd(tempdir())
  on.exit(setwd(old))
  unlink("testgolembrochure", TRUE, TRUE)
  golem::create_golem("testgolembrochure", project_hook = brochure::golem_hook)
  expect_true(
    file.exists("R/mod_home.R")
  )
  expect_true(
    file.exists("R/run_app.R")
  )
  expect_equal(
    readLines(
      system.file(
        "golem/mod_home.R",
        package = "brochure"
      )
    ),
    readLines(
      "R/mod_home.R"
    )
  )

  expect_equal(
    list.files("R"),
    c("app_config.R", "mod_home.R", "run_app.R")
  )

  expect_true(
    grepl(
      "brochure",
      paste(readLines("dev/02_dev.R"), collapse = " ")
    )
  )
})

# Generated by fusen: do not edit by hand

test_that("golem_hook works", {
  x <- tempfile(fileext = ".R")
  new_page("pouet", x)

  tmplt <- readLines(
    x
  )
  expect_true(
    tmplt[1] == "#' pouet UI Function"
  )
  tmplt <- paste(tmplt, collapse = " ")
  expect_true(
    grepl("pouet", tmplt)
  )
  expect_true(
    grepl("page", tmplt)
  )

  skip_if_not_installed("golem")
  old <- setwd(tempdir())
  on.exit(setwd(old))
  unlink("testgolembrochure", TRUE, TRUE)
  golem::create_golem("testgolembrochure", project_hook = brochure::golem_hook)
  golem::add_module(name = "pouet", module_template = brochure::new_page, open = FALSE)
  expect_true(
    file.exists("R/mod_pouet.R")
  )
})