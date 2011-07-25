$.fn.fakeHref = ->
  this.css 'position', 'relative'
  $('<a/>').attr('href', this.attr('fakehref')).css(position: 'absolute', width: '100%', height: '100%', top: 0, left: 0, zindex: 1).appendTo this

$(window).ready ->
  $('[fakehref]').each (_, tag) ->
    $(tag).fakeHref()

