$.fn.fakeCenter = ->
  this.find('>*').wrapAll $('<div/>')
  div = this.find('>div')
  height = (this.height() - div.height()) / 2
  div.css 'padding-top', (height + 'px')
  this

$.fn.fakeBottom = ->
  this.find('>*').wrapAll $('<div/>')
  div = this.find('>div')
  height = (this.height() - div.height()) - 2
  div.css 'padding-top', (height + 'px')
  this

$(window).ready ->
  $('.center').each (_, tag) ->
    $(tag).fakeCenter()

  $('.bottom').each (_, tag) ->
    $(tag).fakeBottom()
