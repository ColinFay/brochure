$( document ).ready(function() {
  Shiny.addCustomMessageHandler('redirect', function(to) {
    // https://www.w3schools.com/howto/howto_js_redirect_webpage.asp
    window.location.href = to
  })
});
