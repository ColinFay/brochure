# Middleware to set cookies

Please read
https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie for
more information. Description of parameters is taken from this page.

## Usage

``` r
set_cookie(
  res,
  name,
  value,
  expires = NULL,
  max_age = NULL,
  domain = NULL,
  path = NULL,
  secure = NULL,
  http_only = NULL,
  same_site = NULL
)

remove_cookie(res, name)
```

## Arguments

- res:

  An httpResponse object

- name:

  A cookie-name can be any US-ASCII characters, except control
  characters, spaces, or tabs. It also must not contain a separator
  character like the following: `( ) < > @ , ; : \ " / [ ] ? = { }`.

  \[ \]: R:%20

- value:

  A cookie-value can optionally be wrapped in double quotes and include
  any US-ASCII characters excluding control characters, Whitespace,
  double quotes, comma, semicolon, and backslash.

- expires:

  The maximum lifetime of the cookie as an HTTP-date timestamp. Please
  enter an ISO 8601 datetime format.

- max_age:

  Number of seconds until the cookie expires. A zero or negative number
  will expire the cookie immediately. If both Expires and Max-Age are
  set, Max-Age has precedence.

- domain:

  Host to which the cookie will be sent.

- path:

  A path that must exist in the requested URL, or the browser won't send
  the Cookie header.

- secure:

  Cookie is only sent to the server when a request is made with the
  https: scheme (except on localhost), and therefore is more resistent
  to man-in-the-middle attacks.

- http_only:

  Forbids JavaScript from accessing the cookie, for example, through the
  Document.cookie property.

- same_site:

  Controls whether a cookie is sent with cross-origin requests,
  providing some protection against cross-site request forgery attacks
  (CSRF).

## Value

the httpResponse, with a cookie header

## Examples

``` r
set_cookie(
  shiny:::httpResponse(),
  "this",
  12
)
#> $status
#> [1] 200
#> 
#> $content_type
#> [1] "text/html; charset=UTF-8"
#> 
#> $content
#> [1] ""
#> 
#> $headers
#> $headers$`X-Content-Type-Options`
#> [1] "nosniff"
#> 
#> $headers$`Set-Cookie`
#> [1] "this=12;"
#> 
#> 
#> attr(,"class")
#> [1] "httpResponse"
```
