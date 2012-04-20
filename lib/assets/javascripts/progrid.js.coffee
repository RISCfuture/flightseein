$.fn.extend
  progrid: (offset) ->
    element = $(this)
    element.find('li:not(.nofade)').css('opacity', '0.0')
    element.find('li:not(.nofade)').each (idx, tag) ->
      img = $(tag)
      img.delay(500 + offset*300 + idx*100).animate({ opacity: '1.0' })

$(window).ready ->
  $('.progrid').each (idx, tag) ->
    $(tag).progrid(idx)
