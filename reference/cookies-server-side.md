# Read the cookies sent with a request

`get_cookies()` returns the raw `Cookie` header of the request the
session was opened with, and `parse_cookie_string()` turns that header
into a named vector.

## Usage

``` r
parse_cookie_string(cookie_string)

get_cookies(session = shiny::getDefaultReactiveDomain())
```

## Arguments

- cookie_string:

  The cookie string to parse, as `get_cookies()` returns it.

- session:

  The `{shiny}` `session` object.

## Value

For `get_cookies()`, the `Cookie` header as a single string, or `NULL`
when the request carried none. For `parse_cookie_string()`, a named
character vector of the cookies it holds, or `""` when given `NULL`.
Index it with single brackets: a visitor arriving without a cookie gives
nothing to index into, and `[[` errors where `[` returns `NA`.

## See also

[`set_cookie()`](https://github.com/ColinFay/brochure/reference/cookie-middleware.md)
to set one from a response handler, and
[`vignette("cookies")`](https://github.com/ColinFay/brochure/articles/cookies.md)
for carrying a session across pages.

## Examples

``` r
parse_cookie_string("brochure_session=63422; brochure_cookie=3958")
#> brochure_session  brochure_cookie 
#>          "63422"           "3958" 
```
