# brochure 1.0.0

First stable release. Routing is rewritten on top of `{routr}`, which brings
parameterised routes and per-method pages, and fixes a family of bugs that came
from keeping the current page in shared state.

## Breaking changes

* `keys` is gone. A parameterised page used to read its matched values from a
  `keys` object that `brochureApp()` installed in the global environment: it
  shadowed any user object of that name and was invisible from a module, a
  golem app or any `local()`. Use `get_keys()` instead — with no argument
  inside a page `server`, and `get_keys(request)` inside a page `ui`.

* `set_cookie()` now defaults to `http_only = TRUE` and `same_site = "Lax"`.
  Pass `http_only = FALSE` or `same_site = NULL` to get the previous header.

* `set_cookie()`, `remove_cookie()` and `server_redirect()` reject values they
  used to interpolate as is: a cookie name, value, domain or path outside the
  RFC 6265 charset, and a redirect target that is neither a path nor an
  `http(s)` URL.

* `...` in `brochureApp()` no longer accepts anything. It takes `page()`s,
  `redirect()`s, tags, tag lists, html dependencies and strings; anything else
  is an error rather than content silently injected into every page. A bare
  list of pages is spliced, so `brochureApp(list(page_1(), page_2()))` now
  builds two pages instead of injecting the list into each of them.

* `page()` and `redirect()` gain a `method` argument, so a page can answer on
  something other than `GET`.

## Bug fixes

* Two people browsing two pages of the same app could each run the other's
  server. The matched page was kept in a single per-app environment, written
  by the http handler and read back when the websocket opened. The page is now
  resolved per request in the ui, and per session in the server.

* An unknown url served the last page visited instead of `content_404`.

* `req_handlers` and `res_handlers` passed to `page()` were stored and never
  run: the documented `/healthcheck` endpoint and the per-page cookies of the
  README were silent no-ops.

* A page whose href had more than one segment (any parameterised route) loaded
  none of its assets: Shiny emits its dependencies as relative urls, and the
  browser resolved them against the parent path. With no `shiny.js` there was
  no websocket, so the page server never ran.

* `basepath` is now removed from the incoming path, as documented, and not
  only prepended to the urls the app emits. Apps work behind a proxy that
  passes the mount through as well as behind one that strips it.

* Two apps in the same R process shared their app level `req_handlers` and
  `res_handlers`, and the last one built won.

* Formulas now work as app level handlers, as the README says they do; only
  page level handlers converted them.

## Other

* The script brochure injects now only registers the handler behind
  `server_redirect()`. It also used to rewrite the page's `<base>`, on the
  premise that the websocket url was computed from it; shiny builds that url
  from `window.location.pathname` instead. Checked on a Posit Connect
  deployment: stripping the script from the response left a deep page with the
  same websocket url, the same rendered output and no failed request.

* `get_mount()` reads the mount from the `RStudio-Connect-App-Base-URL` header
  only when the app really runs on Posit Connect, and keeps the extracted path
  to a plain path. Elsewhere any client could send that header and decide the
  prefix every url of the page is rewritten with.

* The `{routr}` dependency is on the CRAN release, and `{uuid}` and `{fastmap}`
  are no longer needed.
