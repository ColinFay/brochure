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
  # a proxy that already stripped the mount
  expect_equal(strip_basepath("/page2", "/brochure"), "/page2")
  expect_equal(strip_basepath("/page2", ""), "/page2")
})
