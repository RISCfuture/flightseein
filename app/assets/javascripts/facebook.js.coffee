class Facebook
  constructor: (@element, @url) ->
    @data = []
    this.refresh()
    this.setScroll()

  refresh: ->
    this.clear()
    $.ajax @url,
      dataType: 'json'
      error: (xhr, status, error) =>
        this.setError "Couldn't load people: #{if status == 'error' then error else status}."
      success: (data) =>
        this.populate data

  clear: ->
    @element.find('>ul').remove()
    @data = []

  populate: (data) ->
    @data = @data.concat(data) # must clone it

    if @data.length == 0
      $('<p/>').addClass('note').text("No passengers yet.").appendTo @element
      return

    while (people = data.splice(0, 5)).length > 0
      ul = $('<ul/>').appendTo(@element)
      $.each people, (_, person) =>
        li = $('<li/>').attr(fakehref: person.url).css('background-image', "url(#{person.photo})").appendTo(ul)
        $('<h1/>').text(person.name).appendTo li
        p = $('<p/>').text("#{person.hours.toFixed(1)} hours").appendTo li
        p.append ' &bull; '
        p.appendText "#{person.flights} #{if person.flights == 1 then 'flight' else 'flights'}"
        li.fakeBottom().fakeHref()

    if $(window).height() == $(document).height() and data.length > 0
      this.loadNextPage();

  setError: (error) ->
    $('<p/>').addClass('error').text(error).appendTo @element

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
        this.setError "Couldn't load people: #{if status == 'error' then error else status}."
      success: (data) =>
        this.populate data

$.fn.extend
  facebook: (url) ->
    new Facebook(this, url)
