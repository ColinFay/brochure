cat_done <- function() cli::cat_bullet("Done", bullet = "tick", bullet_col = "green")

#' Build a Node JS that serves a brochure app
#'
#' Using the UI object, this function builds
#' a Node JS application with a proxy.
#' That app launches one R process by page, then links
#' one page of your Shiny App to an R process.
#' For example, if you have two pages (/ and /contact),
#' this proxy will launch two R process, and then link
#' / and /contact to a specific process.
#'
#' Of course, this app can be modified after creation if
#' you want to add more features to it.
#' Note that this function requires NodeJS to be installed
#' on your machine and that `{brochure}` wont try to install
#' it.
#'
#' @param ui A Shiny UI object built with `{brochure}`
#' @param path Where to create the Node App.
#' @param fun The R code that launches the app, for example `myapp::run_app()`,
#'     or `shiny::runApp('app.R')`.
#' @param port The port where to serve the proxy, default is `3000`.
#'
#' @importFrom httpuv randomPort
#' @importFrom fs dir_create dir_exists path file_create path_abs
#' @importFrom processx run
#'
#' @return The path to the app.js that serves the proxy.
#' @export

scale <- function(
  ui,
  path,
  fun,
  port = 3000
){
  path <- path_abs(path)
  if (dir_exists(path)) stop("This folder already exists.\nYou need to remove it before creating a new proxy.")

  cli::cat_rule("Creating the folder")
  dir_create(path)
  cat_done()

  cli::cat_rule("Looking for available ports, and building the code")
  ui()
  pages <- names(...multipage)
  ports <- vapply(1:length(pages), function(x) randomPort(), FUN.VALUE = numeric(1))
  code <- c()
  for (i in ports){
    code <- c(
      code,
      sprintf(
        "options(shiny.port = %s, shiny.launch.browser = FALSE);%s",
        i,
        fun
      )
    )
  }
  cat_done()

  cli::cat_rule("npm init -y")
  run(
    "npm", c("init", "-y"),
    wd = path
  )
  cat_done()

  cli::cat_rule("npm install express http-proxy-middleware")
  run(
    "npm", c("install", "express", "http-proxy-middleware"),
    wd = path
  )
  cat_done()

  cli::cat_rule("Building the app.js")
  app_js <- path(
    path, "app", ext = "js"
  )
  file_create(
    app_js
  )
  write_there <- function(...){
    write(..., app_js, append = TRUE)
  }
  write_there("const { createProxyMiddleware } = require('http-proxy-middleware');")
  write_there("const http = require('http');")
  write_there("const { spawn } = require('child_process');")
  write_there(" ")
  write_there("const app = require('express')();")
  write_there("const proxy = createProxyMiddleware({")
  for (i in 1:length(pages)){
    if (pages[i] == "/"){
      write_there(
        sprintf(
          "  target: 'http://localhost:%s', // your brochure / here",
          ports[i]
        )
      )
    }
  }

  write_there("  changeOrigin: true,")
  write_there("  logLevel: 'debug',")
  write_there("  router: {")
  for (i in 1:length(pages)){
    if (pages[i] != "/"){
      write_there(
        sprintf(
          "      '%s': 'http://localhost:%s',",
          pages[i], ports[i]
        )
      )
    }
  }
  write_there("  }")
  write_there("});")
  write_there(" ")
  write_there("app.use(proxy);")
  write_there(" ")
  write_there("const httpServer = http.createServer(app);")
  write_there(" ")

  for (i in code){
    write_there(
      sprintf(
        "spawn(\"Rscript\", [\"-e\", \"options(shiny.port = 4577, shiny.launch.browser = FALSE);%s\"])",
        i
      )
    )
  }

  write_there(" ")
  write_there(
    sprintf(
      "httpServer.listen(%s, () => {",
      port
    )
  )
  write_there(
    sprintf(
      "  console.log('HTTP Server running on port %s');",
      port
    )
  )
  write_there("});")
  write_there(" ")
  write_there("httpServer.on('upgrade', () => {")
  write_there("  proxy.upgrade()")
  write_there("})")
  cat_done()

  return(app_js)
}

# scale(
#   ui,
#   path = "inst/pouetpouet",
#   fun = "shiny::runApp('/Users/colin/Seafile/documents_colin/R/opensource/brochure/inst/app.R')"
# )
#' system("node inst/pouetpouet/app.js")
