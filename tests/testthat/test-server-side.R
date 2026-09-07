test_that("server_redirect only accepts paths and http(s) URLs", {
  expect_equal(check_redirect_to("/page2"), "/page2")
  expect_equal(check_redirect_to("page2"), "page2")
  expect_equal(check_redirect_to("https://example.com/x"), "https://example.com/x")

  expect_error(check_redirect_to("javascript:alert(1)"))
  expect_error(check_redirect_to("JaVaScRiPt:alert(1)"))
  expect_error(check_redirect_to("data:text/html,x"))
  expect_error(check_redirect_to("//evil.example.com"))
  expect_error(check_redirect_to(NULL))
})

test_that("get_mount only trusts the Connect header on Connect", {
  req <- new.env()
  req$HTTP_RSTUDIO_CONNECT_APP_BASE_URL <- "https://connect.example/app/x"

  withr::with_envvar(c(RSTUDIO_PRODUCT = ""), {
    expect_equal(get_mount(req), "")
  })

  withr::with_envvar(c(RSTUDIO_PRODUCT = "CONNECT"), {
    expect_equal(get_mount(req), "/app/x")

    # A path that is not a plain path is dropped rather than reused
    req$HTTP_RSTUDIO_CONNECT_APP_BASE_URL <- "https://connect.example/a b<script>"
    expect_equal(get_mount(req), "")
  })
})

test_that("get_mount falls back on basepath", {
  expect_equal(get_mount(new.env(), "brochure"), "/brochure")
  expect_equal(get_mount(new.env(), "/brochure/"), "/brochure")
  expect_equal(get_mount(new.env()), "")
})
