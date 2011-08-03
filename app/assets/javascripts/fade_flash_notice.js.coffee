$(window).ready ->
  $('#flashes').show() unless $('#flashes').html().trim() == ''

  $('#flash-notice').delay(10000).fadeOut ->
    $('#flash-notice').remove()
    $('#flashes').hide() if $('#flashes').html().trim() == ''
