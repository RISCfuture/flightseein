String::hashCode = ->
  return 0 if this.length == 0
  parseInt this, 36

class Logbook
  constructor: (@element, @url) ->
    @colors = [ 'red', 'yellow', 'green', 'cyan', 'blue', 'magenta' ]
    @data = []
    this.refresh()
    this.setScroll()

  refresh: ->
    this.clear()
    $.ajax @url,
      dataType: 'json'
      error: (xhr, status, error) =>
        this.setError "Couldn't load flights: #{if status == 'error' then error else status}."
      success: (data) =>
        this.populate data

  clear: ->
    @element.find('>li').remove()
    @data = []

  populate: (data) ->
    @data = @data.concat(data)
    
    if @data.length == 0
      $('<li/>').addClass('note').text("No flights yet.").appendTo @element
      return

    $.each data, (_, flight) =>
      li = $('<li/>').addClass(@colors[Math.abs(flight.aircraft.ident.hashCode()) % @colors.length]).appendTo(@element)
      details = $('<details/>').attr('open', 'open').appendTo(li)
      summary = $('<summary/>').appendTo(details)
      $('<time/>').attr('datetime', flight.date).text(flight.date).appendTo summary
      a = $('<a/>').attr('href', flight.url).text("#{flight.aircraft.ident} (#{flight.aircraft.type})").appendTo summary
      a.append " &bull; "
      a.appendText "#{flight.duration.toFixed(1)} hours"
      remarks = $('<p/>').text(flight.remarks).appendTo(details)
      if flight.photos.length > 0
        $('<br/>').appendTo remarks
        for photo in flight.photos
          thumb = $('<a/>').attr(href: photo.full, title: photo.caption).addClass('thumbs').appendTo remarks
          $('<img/>').attr('src', photo.thumbnail).appendTo thumb
        remarks.find('.thumbs').lightBox
          imageLoading: '/images/lightbox/loading.gif'
          imageBtnClose: '/images/lightbox/close.gif'
          imageBtnPrev: '/images/lightbox/prev.gif'
          imageBtnNext: '/images/lightbox/next.gif'
          imageBlank: '/images/lightbox/blank.gif'
          txtImage: ''
      if flight.people.length > 0
        $('<br/>').appendTo remarks
        for person in flight.people
          link = $('<a/>').attr(href: person.url, alt: person.name).appendTo remarks
          $('<img/>').attr('src', person.photo).appendTo link

    if $(window).height() == $(document).height() and data.length > 0
      this.loadNextPage();

  setError: (error) ->
    $('<li/>').addClass('error').text(error).appendTo @element

  setScroll: ->
    $(window).scroll =>
      if $(window).scrollTop() == $(document).height() - $(window).height()
        this.loadNextPage();

  loadNextPage: ->
    return if @data.length == 0
    $.ajax @url,
      data: { last_record: @data[@data.length - 1].id }
      dataType: 'json'
      error: (xhr, status, error) =>
        this.setError "Couldn't load flights: #{if status == 'error' then error else status}."
      success: (data) =>
        this.populate data

$.fn.extend
  logbook: (url) ->
    new Logbook(this, url)
