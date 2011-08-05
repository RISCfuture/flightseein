class Carousel
  constructor: (@element, @url, @orientation, @options={}) ->
    @options = $.extend({ captions: true, lightboxes: true }, @options)
    @element.addClass "carousel-#{@orientation}"
    @data = []

    this.refresh()
    this.setScroll()

  refresh: ->
    this.clear()
    $.ajax @url,
      dataType: 'json',
      error: (xhr, status, error) =>
        this.setError "Couldn't load photos: #{if status == 'error' then error else status}."
      success: (data) =>
        this.populate data

  clear: ->
    @element.find('>li').remove()
    @data = []

  populate: (data) ->
    @data = @data.concat(data) # must clone it

    if @data.length == 0
      this.setNote "No photos yet."
      return

    $.each data, (_, photo) =>
      li = $('<li/>').appendTo(@element)
      fig = $('<figure/>').appendTo(li)
      a = $('<a/>').attr(href: photo.url, title: photo.caption).appendTo(fig)
      $('<img/>').attr('src', photo.preview_url).appendTo a
      $('<figcaption/>').text(photo.caption).appendTo(fig) if @options['captions'] and photo.caption

    if @options['lightboxes']
      @element.find('a').lightBox
        imageLoading: '/images/lightbox/loading.gif'
        imageBtnClose: '/images/lightbox/close.gif'
        imageBtnPrev: '/images/lightbox/prev.gif'
        imageBtnNext: '/images/lightbox/next.gif'
        imageBlank: '/images/lightbox/blank.gif'
        txtImage: ''

    this.loadNextPage() if this.noScroll() and data.length > 0

  setError: (error) ->
    this.clear()
    li = $('<li/>').addClass('center').appendTo @element
    $('<p/>').addClass('error').text(error).appendTo li

  setNote: (note) ->
    this.clear()
    li = $('<li/>').addClass('center').appendTo @element
    $('<p/>').addClass('note').text(note).appendTo li

  setScroll: ->
    @element.scroll =>
      this.loadNextPage() if this.isAtEnd()


  noScroll: ->
    switch @orientation
      when 'horizontal' then @element.width() == @element[0].scrollWidth
      when 'vertical' then @element.height() == @element[0].scrollHeight

  isAtEnd: ->
    switch @orientation
      when 'horizontal' then @element.scrollLeft() == @element[0].scrollWidth - @element.width()
      when 'vertical' then @element.scrollTop() == @element[0].scrollheight - @element.height()

  loadNextPage: ->
    return if @data.length == 0
    $.ajax @url,
      data: { last_record: @data[@data.length - 1].id }
      dataType: 'json'
      error: (xhr, status, error) =>
        this.setError "Couldn't load photos: #{if status == 'error' then error else status}."
      success: (data) =>
        this.populate data

$.fn.extend
  carousel: (url, orient, options={}) ->
    new Carousel(this, url, orient, options)
