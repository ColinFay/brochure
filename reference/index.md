# Package index

## Building an app

The two functions that replace
[`shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html) and organise
its pages.

- [`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md)
  : Create a brochureApp
- [`page()`](https://github.com/ColinFay/brochure/reference/page.md) : A
  Brochure Page

## Moving between pages

Sending the browser somewhere else, from the router or from the server.

- [`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)
  : Redirection
- [`server_redirect()`](https://github.com/ColinFay/brochure/reference/server_redirect.md)
  : Do a server side redirection

## Reading the url

The values a parameterised href matched.

- [`get_keys()`](https://github.com/ColinFay/brochure/reference/get_keys.md)
  : Get the keys of a parameterised page

## Cookies

Setting cookies from a response handler, and reading them back from a
page server.

- [`set_cookie()`](https://github.com/ColinFay/brochure/reference/cookie-middleware.md)
  [`remove_cookie()`](https://github.com/ColinFay/brochure/reference/cookie-middleware.md)
  : Middleware to set cookies
- [`parse_cookie_string()`](https://github.com/ColinFay/brochure/reference/cookies-server-side.md)
  [`get_cookies()`](https://github.com/ColinFay/brochure/reference/cookies-server-side.md)
  : Parse the cookie string

## golem

Using brochure inside a golem application.

- [`golem_hook()`](https://github.com/ColinFay/brochure/reference/golem_hook.md)
  : Golem Hook function
- [`new_page()`](https://github.com/ColinFay/brochure/reference/new_page.md)
  : Add page
