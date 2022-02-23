#' Parse the cookie string
#'
#' @param cookie_string The cookie string to parse
#' @param session The `{shiny}` `session` object.
#'
#' @return a list of cookies and values
#' @rdname cookies-server-side
#' @export
#'
#' @examples
#' parse_cookie_string("brochure_session=63422; brochure_cookie=3958")
parse_cookie_string <- function(cookie_string) {
  if (is.null(cookie_string)) {
    return("")
  }
  couples <- strsplit(cookie_string, ";")[[1]]
  res <- lapply(
    couples,
    function(x) {
      # Small hack to prevent splitting on the trailing =
      nms <- sub("=", "\\\\SPLITHERE\\\\", x)
      nms <- strsplit(nms, "\\\\SPLITHERE\\\\")[[1]]
      res <- gsub("^ +", "", nms[2])
      res <- gsub("[ ^]* +$", "", res)
      names(res) <- gsub("^ +", "", nms[1])
      names(res) <- gsub("[ ^]* +$", "", names(res))
      res
    }
  )
  unlist(res)
}

#' @rdname cookies-server-side
#' @export
get_cookies <- function(session = shiny::getDefaultReactiveDomain()) {
  session$request$HTTP_COOKIE
}


#' Middleware to set cookies
#'
#' Please read https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie
#' for more information.
#' Description of parameters is taken from this page.
#'
#' @param res An httpResponse object
#' @param name A cookie-name can be any US-ASCII characters,
#' except control characters, spaces, or tabs. It also must
#' not contain a separator character like the following:
#'  `( ) < > @ , ; : \ " / [ ] ? = { }`.
#' @param value A cookie-value can optionally be wrapped in
#' double quotes and include any US-ASCII characters excluding
#' control characters, Whitespace, double quotes, comma,
#' semicolon, and backslash.
#' @param expires The maximum lifetime of the cookie as
#' an HTTP-date timestamp. Please enter an ISO 8601 datetime format.
#' @param max_age Number of seconds until the cookie expires.
#' A zero or negative number will expire the cookie immediately.
#' If both Expires and Max-Age are set, Max-Age has precedence.
#' @param domain Host to which the cookie will be sent.
#' @param path A path that must exist in the requested URL,
#'  or the browser won't send the Cookie header.
#' @param secure Cookie is only sent to the server
#' when a request is made with the https: scheme
#' (except on localhost), and therefore is more
#'  resistent to man-in-the-middle attacks.
#' @param http_only Forbids JavaScript from accessing the
#'  cookie, for example, through the Document.cookie property.
#' @param same_site Controls whether a cookie is sent with
#' cross-origin requests, providing some protection against
#' cross-site request forgery attacks (CSRF).
#'
#' @return the httpResponse, with a cookie header
#' @export
#' @rdname cookie-middleware
#'
#' @examples
#' set_cookie(
#'   shiny:::httpResponse(),
#'   "this",
#'   12
#' )
set_cookie <- function(
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
) {
  attempt::stop_if(
    name,
    missing,
    "`name` is required "
  )
  attempt::stop_if(
    name,
    missing,
    "`value` is required "
  )

  cook <- sprintf("%s=%s;", name, value)

  if (!is.null(expires)) {
    cook <- sprintf(
      "%s Expires = %s;",
      cook,
      http_date(as.POSIXlt(expires, tz = "GMT"))
    )
  }

  if (!is.null(max_age)) {
    cook <- sprintf(
      "%s Max-Age = %s;",
      cook,
      max_age
    )
  }

  if (!is.null(domain)) {
    cook <- sprintf(
      "%s Domain = %s;",
      cook,
      domain
    )
  }

  if (!is.null(path)) {
    cook <- sprintf(
      "%s Path = %s;",
      cook,
      path
    )
  }

  if (!is.null(secure) && secure) {
    cook <- sprintf(
      "%s Secure;",
      cook
    )
  }

  if (!is.null(http_only) && http_only) {
    cook <- sprintf(
      "%s HttpOnly;",
      cook
    )
  }

  if (!is.null(same_site)) {
    attempt::stop_if_not(
      same_site,
      ~ .x %in% c("Strict", "Lax", "None"),
      'same_site should be one of "Strict", "Lax", "None"'
    )
    cook <- sprintf(
      "%s SameSite = %s;",
      cook,
      same_site
    )
  }

  res$headers$`Set-Cookie` <- cook
  res
}

#' @export
#' @rdname cookie-middleware
remove_cookie <- function(
  res,
  name
) {
  res$headers$`Set-Cookie` <- sprintf(
    "%s=''; Max-Age=0",
    name
  )
  res
}

# HTTP Date is stupid
# https://developer.mozilla.org/fr/docs/Web/HTTP/Headers/Date
http_date <- function(date) {
  # Borrowed from https://github.com/r-lib/gargle/blob/132d549871ab5d80ae20d21c5b465fdd80ca0f6c/R/shiny.R#L250
  sprintf(
    "%s, %02s %s %04s %02s:%02s:%02s GMT",
    c(
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun"
    )[
      date$wday + 1
    ],
    date$mday,
    c(
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    )[
      date$mon + 1
    ],
    date$year + 1900,
    date$hour,
    date$min,
    date$sec
  )
}
