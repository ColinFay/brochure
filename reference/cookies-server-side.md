# Parse the cookie string

Parse the cookie string

## Usage

``` r
parse_cookie_string(cookie_string)

get_cookies(session = shiny::getDefaultReactiveDomain())
```

## Arguments

- cookie_string:

  The cookie string to parse

- session:

  The `{shiny}` `session` object.

## Value

a list of cookies and values

## Examples

``` r
parse_cookie_string("brochure_session=63422; brochure_cookie=3958")
#> brochure_session  brochure_cookie 
#>          "63422"           "3958" 
```
