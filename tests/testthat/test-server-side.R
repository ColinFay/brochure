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
  # The value observed on a real Connect deployment
  req$HTTP_RSTUDIO_CONNECT_APP_BASE_URL <-
    "https://connect.thinkr.fr/content/7cdecc70-54e0-41b4-b3bf-8dc02fdf71af"

  withr::with_envvar(c(RSTUDIO_PRODUCT = "", POSIT_PRODUCT = ""), {
    expect_equal(get_mount(req), "")
  })

  for (var in c("RSTUDIO_PRODUCT", "POSIT_PRODUCT")) {
    withr::with_envvar(stats::setNames(list("CONNECT"), var), {
      expect_equal(
        get_mount(req),
        "/content/7cdecc70-54e0-41b4-b3bf-8dc02fdf71af"
      )
    })
  }

  withr::with_envvar(c(RSTUDIO_PRODUCT = "CONNECT"), {
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

test_that("normalize_basepath accepts every spelling of a mount", {
  expect_equal(normalize_basepath("brochure"), "/brochure")
  expect_equal(normalize_basepath("/brochure"), "/brochure")
  expect_equal(normalize_basepath("/brochure/"), "/brochure")
  expect_equal(normalize_basepath(""), "")
})

test_that("strip_basepath only drops a whole segment", {
  expect_equal(strip_basepath("/brochure/page2", "/brochure"), "/page2")
  expect_equal(strip_basepath("/brochure", "/brochure"), "/")
  expect_equal(strip_basepath("/brochure/", "/brochure"), "/")
  # "/brochurette" is not mounted under "/brochure"
  expect_equal(strip_basepath("/brochurette/x", "/brochure"), "/brochurette/x")
  # Connect strips the mount before forwarding: nothing left to drop
  expect_equal(strip_basepath("/page2", "/brochure"), "/page2")
  expect_equal(strip_basepath("/page2", ""), "/page2")
})
