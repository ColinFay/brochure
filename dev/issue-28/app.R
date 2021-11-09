library(shiny)
library(brochure)
# We'll start by defining a home page
home <- function(
    httr_code
){
    page(
        href = "/",
        # Simple UI, no server side
        ui = tagList(
            tags$link(rel = "stylesheet", href = "www/site.css"),
            tags$h1("Hello world!"), 
            tags$p("Open a new R console and run:"),
            tags$pre(
                httr_code
            )
        ), 
        server = function(input, output, session){
            addResourcePath("www", "www")
        }
    )
}

postpage <- function(){
    page(
        href = "/post",
        # We'll handle POST requests via a request handler
        req_handlers = list(
            function(req){
                # This is where the magic happens
                # Our req object contains a `REQUEST_METHOD` 
                # entry that contains the HTTP verb used 
                # to perform the request
                if( req$REQUEST_METHOD == "POST" ){
                    print("In POST!")
                    # Because we want the HTTP request to be 
                    # completed here, we return an httpResponse object here. 
                    # httpResponse() is exported since {shiny} 1.6.0, 
                    # otherwise you'll have to ::: (shiny:::httpResponse)
                    return(
                        httpResponse(
                            # 201 is the HTTP code you'll send back when 
                            # you have created a resource on the server
                            status = 201, 
                            content = "ok"
                        )
                    )
                } 
                # Whenever we're not in a POST, we'll simply return 
                # req, which will the move to standard {shiny} handling, 
                # i.e. calling ui and server.
                return(req)
            }
        ), 
        ui = tagList(
            tags$p("Hello from /post!")
        )
    )
}
# For the sake of reproducibility:
options(shiny.port = 2811)

brochureApp(
    home(
        httr_code = "httr::POST('http://127.0.0.1:2811/post')"
    ),
    postpage()
)