test_that("set_cookie works", {
  res <- shiny:::httpResponse()
  expect_error(
    set_cookie(
      res
    )
  )
  expect_error(
    set_cookie(
      res,
      "this"
    )
  )
  expect_error(
    set_cookie(
      res,
      value = 12
    )
  )
  output <- set_cookie(
    res,
    "this",
    12
  )
  cook <- parse_cookie_string(
    output$headers$`Set-Cookie`
  )
  expect_equal(
    cook,
    c(this = "12")
  )

  output <- set_cookie(
    res,
    "this",
    12,
    expires = "2021-11-28 09:00:00"
  )

  cook <- parse_cookie_string(
    output$headers$`Set-Cookie`
  )
  expect_equal(
    cook["Expires"],
    c(Expires = "Mon, 28 Nov 2021 09:00:00 GMT")
  )

  output <- set_cookie(
    res,
    "this",
    12,
    max_age = "0"
  )

  cook <- parse_cookie_string(
    output$headers$`Set-Cookie`
  )

  expect_equal(
    cook["Max-Age"],
    c(`Max-Age` = "0")
  )

  output <- set_cookie(
    res,
    "this",
    12,
    domain = "Colinfay"
  )

  cook <- parse_cookie_string(
    output$headers$`Set-Cookie`
  )

  expect_equal(
    cook["Domain"],
    c(`Domain` = "Colinfay")
  )

  output <- set_cookie(
    res,
    "this",
    12,
    path = "/this"
  )

  cook <- parse_cookie_string(
    output$headers$`Set-Cookie`
  )

  expect_equal(
    cook["Path"],
    c(`Path` = "/this")
  )

  output <- set_cookie(
    res,
    "this",
    12,
    secure = TRUE
  )

  cook <- parse_cookie_string(
    output$headers$`Set-Cookie`
  )

  expect_equal(
    cook["Secure"],
    c(`Secure` = NA_character_)
  )

  output <- set_cookie(
    res,
    "this",
    12,
    secure = FALSE
  )

  cook <- parse_cookie_string(
    output$headers$`Set-Cookie`
  )

  expect_false(
    "Secure" %in% names(cook)
  )

  output <- set_cookie(
    res,
    "this",
    12,
    http_only = TRUE
  )

  cook <- parse_cookie_string(
    output$headers$`Set-Cookie`
  )

  expect_equal(
    cook["HttpOnly"],
    c(`HttpOnly` = NA_character_)
  )

  output <- set_cookie(
    res,
    "this",
    12,
    http_only = FALSE
  )

  cook <- parse_cookie_string(
    output$headers$`Set-Cookie`
  )

  expect_false(
    "HttpOnly" %in% names(cook)
  )

  output <- set_cookie(
    res,
    "this",
    12,
    same_site = "Lax"
  )

  cook <- parse_cookie_string(
    output$headers$`Set-Cookie`
  )

  expect_equal(
    cook["SameSite"],
    c(`SameSite` = "Lax")
  )

  expect_error(
    set_cookie(
      res,
      "this",
      12,
      same_site = "gouigoui"
    )
  )
})


test_that("parse_cookie_string works", {
  res <- parse_cookie_string(
    "_ga=AA; _ga_Z0FXMLE2RM=BB; br-acc=xyz="
  )
  expect_equal(
    res["_ga"],
    c("_ga" = "AA")
  )
  expect_equal(
    res["_ga_Z0FXMLE2RM"],
    c("_ga_Z0FXMLE2RM" = "BB")
  )
  expect_equal(
    res["br-acc"],
    c("br-acc" = "xyz=")
  )
})