#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}.
#'     DO NOT REMOVE.
#' @import shiny
#' @noRd
app_server <- function(input, output, session) {
  # Your application server logic
  # THIS PART WILL BE RENDERED ON ALL PAGES

  # Enabling the brochure mechanism
  brochure_enable(basepath = "brochure")

  r <- reactiveValues()

  observeEvent(
    TRUE,
    {
      # Fetch the cookies using {glouton}
      r$cook <- fetch_cookies()

      # If there is no stored cookie for {brochure}, we generate it
      if (is.null(r$cook$brochure_cookie)) {
        # Generate a random id
        session_id <- digest::sha1(paste(Sys.time(), sample(letters, 16)))
        # Add this id as a cookie
        add_cookie("brochure_cookie", session_id)
        # Store in in the reactiveValues list
        r$cook$brochure_cookie <- session_id
      }
      # For debugging purpose
      print(r$cook$brochure_cookie)
    },
    # We only need to do it once doing it once
    once = TRUE
  )

  # THIS PART WILL ONLY BE RENDERED ON /

  observeEvent(input$textenter, {
    # Use the session id to save on the cache system
    cache_system$set(
      paste0(
        r$cook$brochure_cookie,
        "text"
      ),
      input$textenter
    )
  })



  output$plota <- renderPlot({
    print("In /")
    plot(mtcars)
  })

  # THIS PART WILL ONLY BE RENDERED ON /page2

  output$textdisplay <- renderPrint({
    # Getting the content value based on the session cookie
    cache_system$get(
      paste0(
        r$cook$brochure_cookie,
        "text"
      )
    )
  })

  output$plotb <- renderPlot({
    print("In /page2")
    plot(airquality)
  })
}
