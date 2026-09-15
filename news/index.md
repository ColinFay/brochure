# Changelog

## brochure 1.0.0

First stable release. Routing is rewritten on top of
[routr](https://routr.data-imaginist.com), which brings parameterised
routes and per-method pages, and fixes a family of bugs that came from
keeping the current page in shared state.

### Breaking changes

- `keys` is gone. A parameterised page used to read its matched values
  from a `keys` object that
  [`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md)
  installed in the global environment: it shadowed any user object of
  that name and was invisible from a module, a golem app or any
  [`local()`](https://rdrr.io/r/base/eval.html). Use
  [`get_keys()`](https://github.com/ColinFay/brochure/reference/get_keys.md)
  instead — with no argument inside a page `server`, and
  `get_keys(request)` inside a page `ui`.

- [`set_cookie()`](https://github.com/ColinFay/brochure/reference/cookie-middleware.md)
  now defaults to `http_only = TRUE` and `same_site = "Lax"`. Pass
  `http_only = FALSE` or `same_site = NULL` to get the previous header.

- [`set_cookie()`](https://github.com/ColinFay/brochure/reference/cookie-middleware.md),
  [`remove_cookie()`](https://github.com/ColinFay/brochure/reference/cookie-middleware.md)
  and
  [`server_redirect()`](https://github.com/ColinFay/brochure/reference/server_redirect.md)
  reject values they used to interpolate as is: a cookie name, value,
  domain or path outside the RFC 6265 charset, and a redirect target
  that is neither a path nor an `http(s)` URL.

- `...` in
  [`brochureApp()`](https://github.com/ColinFay/brochure/reference/brochureApp.md)
  no longer accepts anything. It takes
  [`page()`](https://github.com/ColinFay/brochure/reference/page.md)s,
  [`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)s,
  tags, tag lists, html dependencies and strings; anything else is an
  error rather than content silently injected into every page. A bare
  list of pages is spliced, so `brochureApp(list(page_1(), page_2()))`
  now builds two pages instead of injecting the list into each of them.

- [`page()`](https://github.com/ColinFay/brochure/reference/page.md) and
  [`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)
  gain a `method` argument, so a page can answer on something other than
  `GET`.

### Bug fixes

- Two people browsing two pages of the same app could each run the
  other’s server. The matched page was kept in a single per-app
  environment, written by the http handler and read back when the
  websocket opened. The page is now resolved per request in the ui, and
  per session in the server.

- An unknown url served the last page visited instead of `content_404`.

- `req_handlers` and `res_handlers` passed to
  [`page()`](https://github.com/ColinFay/brochure/reference/page.md)
  were stored and never run: the documented `/healthcheck` endpoint and
  the per-page cookies of the README were silent no-ops.

- A page whose href had more than one segment (any parameterised route)
  loaded none of its assets: Shiny emits its dependencies as relative
  urls, and the browser resolved them against the parent path. With no
  `shiny.js` there was no websocket, so the page server never ran.

- `basepath` is now removed from the incoming path, as documented, and
  not only prepended to the urls the app emits. Apps work behind a proxy
  that passes the mount through as well as behind one that strips it.

- [`remove_cookie()`](https://github.com/ColinFay/brochure/reference/cookie-middleware.md)
  could not delete a cookie set with an explicit `path` or `domain`. A
  cookie is only replaced when name, path and domain all match, and the
  deletion header carried none of them, so the browser scoped it to the
  directory of the current request and left the original cookie alone.
  Behind a mount that directory is not `/`, so the documented
  login/logout pattern silently failed on Posit Connect. It now takes
  `path` and `domain`.

- Pages and redirects are matched in the order they were passed.
  Redirects were registered after every page whatever the order, so a
  [`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)
  declared before a
  [`page()`](https://github.com/ColinFay/brochure/reference/page.md) at
  the same href never answered.

- [`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)
  accepts only the statuses a browser follows: 301, 302, 303, 307
  and 308. The allow-list read `c(301:308, 310)`, which admitted 304,
  305, 306 and 310 — none of which make a browser follow a `Location`.

- `basepath` has to be a plain url path. It is interpolated into urls
  and into the injected javascript, where a quote in it closed the
  string literal.

- Mount rewriting is blind to capitalisation, so `<IMG SRC="logo.png">`
  is rewritten like its lowercase equivalent.

- An explicit `basepath` now decides the mount even on Posit Connect.
  The header used to win, so an app that set `basepath` to pin the
  behaviour was stripping the incoming path with one mount and writing
  its urls with another.

- [`server_redirect()`](https://github.com/ColinFay/brochure/reference/server_redirect.md)
  and
  [`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)
  refuse a backslash anywhere in the target. A URL parser reads it as a
  slash, so `"\page2"` was the root and escaped the mount, which is only
  ever prefixed onto a `/`.

- Mount rewriting handles single quoted attributes, so
  `HTML("<img src='logo.png'>")` is rewritten like its double quoted
  equivalent.

- A page declared with a method other than `GET` can serve its document.
  Shiny’s UI handler answers `GET` alone unless the ui says otherwise,
  so such a page returned nothing unless a request handler answered for
  it.

- [`server_redirect()`](https://github.com/ColinFay/brochure/reference/server_redirect.md)
  and
  [`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)
  refuse an empty target, which is neither a path nor a url: the browser
  dropped it silently, and the HTTP redirect emitted an empty
  `Location`.

- [`set_cookie()`](https://github.com/ColinFay/brochure/reference/cookie-middleware.md)
  checks `max_age`, the one part still interpolated into the header
  unexamined: `max_age = "0\r\nX-Injected: 1"` appended a header of its
  own.

- [`server_redirect()`](https://github.com/ColinFay/brochure/reference/server_redirect.md)
  refuses a protocol relative target written with backslashes. A URL
  parser reads `\` as `/`, so `"\\host"` and `"/\host"` left the app
  exactly as `"//host"` did.

- Mount rewriting only touches real attributes, and covers form
  `action`. It matched anywhere in the response, so page text or inline
  javascript holding `src="logo.png"` was rewritten too; and a form
  posting to `/submit` under a mount went to the domain root.

- [`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)
  did not check `to`, which goes straight into a `Location` header: a
  CRLF in it appended a header of its own. It is now held to the same
  rule as
  [`server_redirect()`](https://github.com/ColinFay/brochure/reference/server_redirect.md).

- An internal
  [`redirect()`](https://github.com/ColinFay/brochure/reference/redirect.md)
  sent the browser out of the app when it was mounted under a prefix.
  The redirect answers before anything is rewritten, so its `Location`
  was emitted unprefixed.

- A page declared with a method other than `GET` never ran its server.
  The websocket handshake is a `GET` whatever the page answers on, so it
  matched no route; sessions are now resolved against the path alone.

- A root absolute resource url such as `src="/img.png"` was left outside
  the app under a mount, while a relative navigation link such as
  `<a href="contact">` was rewritten to `/contact`, moving where its
  author pointed it. Resource urls and navigation links are now treated
  separately.

- Two apps in the same R process shared their app level `req_handlers`
  and `res_handlers`, and the last one built won.

- Formulas now work as app level handlers, as the README says they do;
  only page level handlers converted them.

- An app behind a proxy that passes its mount through – shinyProxy, or
  an nginx `proxy_pass` without a trailing slash – loaded none of its
  assets. Shiny’s resource paths are served by httpuv before R and
  matched against the raw path, so `/myapp/jquery-3.7.1/jquery.min.js`
  matched no static path and landed on brochure, which answered
  `content_404`. Without `shiny.js` there was no websocket, so no page
  was ever interactive. Such a request now falls through to the handler
  Shiny keeps for it. Checked from a browser against `inst/subpage`
  behind both kinds of proxy: 41 checks pass on each, where the
  pass-through one failed on the first page.

- `/reactlog` is served again. Every path brochure did not route got
  `content_404`, and Shiny’s own handler for that endpoint comes after
  the app’s in the chain, so `options(shiny.reactlog = TRUE)` and
  Ctrl+F3 answered

  404. 

- Two pages carrying two
  [`bslib::bs_theme()`](https://rstudio.github.io/bslib/reference/bs_theme.html)s
  no longer fight over one url. Shiny builds a dependency’s url prefix
  from its name and version, and both themes ship `bootstrap` at the
  same version from two different compiled directories: the page
  rendered last took the prefix, and the browser then styled pages with
  whichever css it had cached under it. Each source directory now gets
  its own prefix.

### Other

- The script brochure injects now only registers the handler behind
  [`server_redirect()`](https://github.com/ColinFay/brochure/reference/server_redirect.md).
  It also used to rewrite the page’s `<base>`, on the premise that the
  websocket url was computed from it; shiny builds that url from
  `window.location.pathname` instead. Checked on a Posit Connect
  deployment: stripping the script from the response left a deep page
  with the same websocket url, the same rendered output and no failed
  request.

- `get_mount()` reads the mount from the `RStudio-Connect-App-Base-URL`
  header only when the app really runs on Posit Connect, and keeps the
  extracted path to a plain path. Elsewhere any client could send that
  header and decide the prefix every url of the page is rewritten with.

- The [routr](https://routr.data-imaginist.com) dependency is on the
  CRAN release, and [uuid](https://www.rforge.net/uuid) and
  [fastmap](https://r-lib.github.io/fastmap/) are no longer needed.

- [`golem_hook()`](https://github.com/ColinFay/brochure/reference/golem_hook.md)
  leaves a tested app: it writes a test for the page it creates, along
  with the testthat structure to run it under `R CMD check`, and adds
  brochure to the Imports of the app it hooks – the module template
  calls
  [`page()`](https://github.com/ColinFay/brochure/reference/page.md), so
  nothing the hook wrote could be loaded or tested without it.

- The golem recommended tests come in a brochure version, and
  [`golem::use_recommended_tests()`](https://thinkr-open.github.io/golem/reference/use_recommended.html)
  is taken out of `dev/01_start.R`. The ones golem writes drive
  `app_ui()` and `app_server()`, which the hook deletes: a freshly
  created app failed its own test suite. What replaces them is the app
  object and the page it serves on `/`.

- [`vignette("design")`](https://github.com/ColinFay/brochure/articles/design.md)
  says how a brochure app behaves with several visitors at once: a
  session is one visitor on one page, they all share one R process, and
  a page that blocks holds up every other page.

- [`vignette("handlers")`](https://github.com/ColinFay/brochure/articles/handlers.md)
  and [`?page`](https://github.com/ColinFay/brochure/reference/page.md)
  say why a page on a method other than `GET` is unreachable when the
  app has a `www/` directory at its root: Shiny mounts it as a static
  path on `/`, and httpuv answers anything that is not a `GET` or a
  `HEAD` from there with a 400 before R sees the request.

- Seven vignettes and a pkgdown site.
  [`vignette("brochure")`](https://github.com/ColinFay/brochure/articles/brochure.md)
  gets you started,
  [`vignette("handlers")`](https://github.com/ColinFay/brochure/articles/handlers.md)
  covers the request and response middleware,
  [`vignette("cookies")`](https://github.com/ColinFay/brochure/articles/cookies.md)
  the cookie API and carrying a session between pages,
  [`vignette("design")`](https://github.com/ColinFay/brochure/articles/design.md)
  what changes when an app is several pages,
  [`vignette("deployment")`](https://github.com/ColinFay/brochure/articles/deployment.md)
  serving the app under a prefix,
  [`vignette("testing")`](https://github.com/ColinFay/brochure/articles/testing.md)
  testing the routing and the pages, and
  [`vignette("golem")`](https://github.com/ColinFay/brochure/articles/golem.md)
  building a brochure app as a golem package.
