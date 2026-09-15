# The golem recommended tests, for an app whose ui and server are its pages.
# `app_ui()` and `app_server()` do not exist here: brochure resolves a page
# per request, so what replaces them is the app object and what it serves.

test_that("run_app() builds a Shiny app", {
	app <- run_app()
	expect_s3_class(app, "shiny.appobj")
	# Check that formals have not been removed
	fmls <- formals(run_app)
	for (i in c("onStart", "options", "enableBookmarking")) {
		expect_true(i %in% names(fmls))
	}
})

test_that("the app serves its home page", {
	# A request in the shape httpuv hands one to the app.
	# `vignette("testing", package = "brochure")` covers this in full.
	req <- new.env(parent = emptyenv())
	req$REQUEST_METHOD <- "GET"
	req$PATH_INFO <- "/"
	req$QUERY_STRING <- ""
	req$SCRIPT_NAME <- ""
	req$SERVER_NAME <- "127.0.0.1"
	req$SERVER_PORT <- "3000"
	req$HTTP_HOST <- "127.0.0.1:3000"
	req$rook.url_scheme <- "http"
	req$rook.version <- "1.1-0"

	res <- run_app()$httpHandler(req)
	expect_equal(res$status, 200)
	expect_true(
		grepl("Hello {brochure}!", res$content, fixed = TRUE)
	)
})

test_that("app_sys works", {
	expect_true(
		app_sys("golem-config.yml") != ""
	)
})

test_that("golem-config works", {
	config_file <- app_sys("golem-config.yml")
	skip_if(config_file == "")

	expect_true(
		get_golem_config(
			"app_prod",
			config = "production",
			file = config_file
		)
	)
	expect_false(
		get_golem_config(
			"app_prod",
			config = "dev",
			file = config_file
		)
	)
})

# Configure this test to fit your need
test_that("app launches", {
	golem::expect_running(sleep = 5)
})
