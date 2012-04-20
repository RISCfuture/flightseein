class Uploader
  constructor: (elem, @url, @name, @options={}) ->
    @method = @options.method || 'POST'
    @element = $(elem)

    @activeUploads = 0
    @successfulUploads = 0
    @failedUploads = 0
    @pendingUploads = []

    @element.text "Drag files here to upload"

    @element.bind 'dragenter', (event) ->
      event.stopPropagation()
      event.preventDefault()
      false
    @element.bind 'dragover', (event) ->
      event.stopPropagation()
      event.preventDefault()
      false
    @element.bind 'drop', this.drop

  drop: (event) =>
    event.stopPropagation()
    event.preventDefault()

    @element.text ''

    $.each event.originalEvent.dataTransfer.files, (_, file) =>
      this.upload file

  isFinished: =>
    @activeUploads == 0 && @pendingUploads.length == 0

  isFailed: =>
    @failedUploads > 0

  upload: (file) =>
    if @options.maxSimultaneousUploads && @activeUploads > @options.maxSimultaneousUploads
       @pendingUploads.push file
       return

    @activeUploads++
    uid = Math.round(Math.random()*0x1000000).toString(16); # so that the listeners can keep their files apart
    @options.startHandler(uid, file) if @options.startHandler

    xhr = new XMLHttpRequest()

    data = new FormData()
    data.append @name, file
    data.append @options.csrfProtection[0], @options.csrfProtection[1] if @options.csrfProtection

    xhr.addEventListener 'load', (event) =>
      @activeUploads--
      if xhr.status >= 400 then @failedUploads++ else @successfulUploads++
      this.upload @pendingUploads.pop() if @pendingUploads.length > 0
    xhr.addEventListener 'error', (event) =>
      @activeUploads--
      @failedUploads++
      this.upload @pendingUploads.pop() if @pendingUploads.length > 0

    if @options.progressHandler
      xhr.upload.addEventListener 'progress', (event) =>
        @options.progressHandler uid, 'upload', event.position, event.total
      xhr.addEventListener 'progress', (event) =>
        @options.progressHandler uid, 'download', event.position, event.total
    if @options.uploadFinishedHandler
      xhr.upload.addEventListener 'load', (event) =>
        @options.uploadFinishedHandler uid
    if @options.errorHandler
      xhr.addEventListener 'error', (event) =>
        @options.errorHandler uid, xhr
    if @options.loadHandler
      xhr.addEventListener 'load', (event) =>
        @options.loadHandler uid, xhr

    xhr.open @method, @url, true
    xhr.send data

$.fn.extend
  uploader: (url, name, options={}) ->
    new Uploader(this, url, name, options)
