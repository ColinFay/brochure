# Redirection

Answers an url with an HTTP redirection, before any Shiny code runs. To
redirect from inside a page server instead, see
[`server_redirect()`](https://github.com/ColinFay/brochure/reference/server_redirect.md).

## Usage

``` r
redirect(from, to, code = 301, method = "GET")
```

## Arguments

- from:

  the url to redirect from

- to:

  the url to redirect to

- code:

  redirecting http code, one of 301, 302, 303, 307 or 308

- method:

  The HTTP method the redirection answers to. Defaults to `"GET"`.

## Value

A `redirect` object, to be passed to
[`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md).

## See also

[`server_redirect()`](https://github.com/ColinFay/brochure/reference/server_redirect.md)
to redirect from inside a page server.

## Examples

``` r
redirect(
  from = "/index.html",
  to = "/"
)
#> $from
#> [1] "/index.html"
#> 
#> $to
#> [1] "/"
#> 
#> $code
#> [1] 301
#> 
#> $method
#> [1] "GET"
#> 
#> attr(,"class")
#> [1] "redirect" "list"    

# 301 says the move is permanent, 302 that it is temporary
redirect(
  from = "/old",
  to = "/new",
  code = 302
)
#> $from
#> [1] "/old"
#> 
#> $to
#> [1] "/new"
#> 
#> $code
#> [1] 302
#> 
#> $method
#> [1] "GET"
#> 
#> attr(,"class")
#> [1] "redirect" "list"    
```
