% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/cookie.R
\name{set_cookie}
\alias{set_cookie}
\alias{remove_cookie}
\title{Middleware to set cookies}
\usage{
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
}
\arguments{
\item{res}{An httpResponse object}

\item{name}{A cookie-name can be any US-ASCII characters,
except control characters, spaces, or tabs. It also must
not contain a separator character like the following:
\verb{( ) < > @ , ; : \\ " / [ ] ? = \{ \}}.

[ ]: R:\%20}

\item{value}{A cookie-value can optionally be wrapped in
double quotes and include any US-ASCII characters excluding
control characters, Whitespace, double quotes, comma,
semicolon, and backslash.}

\item{expires}{The maximum lifetime of the cookie as
an HTTP-date timestamp. Please enter an ISO 8601 datetime format.}

\item{max_age}{Number of seconds until the cookie expires.
A zero or negative number will expire the cookie immediately.
If both Expires and Max-Age are set, Max-Age has precedence.}

\item{domain}{Host to which the cookie will be sent.}

\item{path}{A path that must exist in the requested URL,
or the browser won't send the Cookie header.}

\item{secure}{Cookie is only sent to the server
when a request is made with the https: scheme
(except on localhost), and therefore is more
resistent to man-in-the-middle attacks.}

\item{http_only}{Forbids JavaScript from accessing the
cookie, for example, through the Document.cookie property.}

\item{same_site}{Controls whether a cookie is sent with
cross-origin requests, providing some protection against
cross-site request forgery attacks (CSRF).}
}
\value{
the httpResponse, with a cookie header
}
\description{
Please read https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Set-Cookie
for more information.
Description of parameters is taken from this page.
}
\examples{
set_cookie(
  shiny:::httpResponse(),
  "this",
  12
)
}
