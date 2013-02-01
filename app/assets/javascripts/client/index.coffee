# Utils

bind = (element, name, callback) ->
  if element.addEventListener
    element.addEventListener(name, callback, false)
  else
    element.attachEvent("on#{name}", callback)

host = (url) ->
  # IE6 only resolves resolves hrefs using innerHTML
  parent = document.createElement('div')
  parent.innerHTML = "<a href=\"#{url}\">x</a>"
  parser = parent.firstChild
  "#{parser.host}"

request = (url, params = {}, callback) ->
  # Prevent caching
  params.i     = new Date().getTime()
  params       = ("#{k}=#{encodeURIComponent(v)}" for k,v of params).join('&')

  image        = new Image
  image.onload = callback if callback
  image.src    = "#{url}?#{params}"

  true

setCookie = (name, value, options = {}) ->
  if options.expires is true
    options.expires = -1

  if typeof options.expires is 'number'
    expires = new Date
    expires.setTime(expires.getTime() + options.expires*24*60*60*1000)
    options.expires = expires

  options.path ?= '/'

  value  = (value + '').replace(/[^!#-+\--:<-\[\]-~]/g, encodeURIComponent)
  cookie = encodeURIComponent(name) + '=' + value

  cookie += ';expires=' + options.expires.toGMTString() if options.expires
  cookie += ';path=' + options.path if options.path
  document.cookie = cookie

getCookie = (name) ->
  cookies = document.cookie.split('; ')
  for cookie in cookies
    index = cookie.indexOf('=')
    key   = decodeURIComponent(cookie.substr(0, index))
    value = decodeURIComponent(cookie.substr(index + 1))
    return value if key is name
  null

# Public

class @Abba
  @endpoint: 'http://localhost:4567'

  constructor: (name, options = {}) ->
    unless name
      throw new Error('Experiment name required')

    # Force constructor
    if this not instanceof Abba
      return new Abba(name, options)

    @name     = name
    @options  = options
    @variants = []

    @endpoint = @options.endpoint or @constructor.endpoint

  variant: (name, callback) ->
    if typeof name isnt 'string'
      throw new Error('Variant name required')

    @variants.push(name: name, callback: callback)
    this

  control: (name = 'Control', callback) =>
    @variants.push(name: name, callback: callback, control: true)
    this

  start: =>
    # Choose a random variant
    @result ?= Math.floor(Math.random() * @variants.length)

    if previous = @getVariantCookie()
      # Use the same variant as before
      variant = (v for v in @variants when v.name is previous)[0]

    else
      # Or choose a random one
      variant = @variants[@result]

      throw new Error('No valid variant') unless variant

      # Record which experiment was run on the server
      request(
        "#{@endpoint}/start",
        experiment: @name,
        variant:    variant.name,
        control:    variant.control or false
      )

      # Set the variant we chose as a cookie
      @setVariantCookie(variant.name)

    variant?.callback?()
    @chosen = variant
    this

  # Complete experiment now
  complete: (name) =>
    # Optionally pass a name, or read from the cookie
    name or= @getVariantCookie()
    return this unless name

    # If the test has already been completed, return
    return this if @hasPersistCompleteCookie()

    # Preserve or reset test
    if @options.persist
      @setPersistCompleteCookie()
    else
      @reset()

    # Request complete now, or on the next request
    if @options.delay
      @setDelayCompleteCookie(name)
    else
      @requestComplete(name)

    this

  reset: =>
    @removeVariantCookie()
    @removePersistCompleteCookie()
    @result = null

  # Private

  requestComplete: (name) =>
    # Record the experiment was completed on the server
    request("#{@endpoint}/complete", experiment: @name, variant: name)

  # Variant Cookie

  getVariantCookie: =>
    getCookie("abbaVariant_#{@name}")

  setVariantCookie: (value) =>
    setCookie("abbaVariant_#{@name}", value, expires: 600)

  removeVariantCookie: =>
    setCookie("abbaVariant_#{@name}", '', expires: true)

  # Complete Cookie

  setDelayCompleteCookie: (value) =>
    setCookie('abbaDelayComplete', "#{@name}##{value}")

  setPersistCompleteCookie: =>
    setCookie("abbaPersistComplete_#{@name}", '1', expires: 600)

  hasPersistCompleteCookie: =>
    !!getCookie("abbaPersistComplete_#{@name}")

  removePersistCompleteCookie: =>
    setCookie("abbaPersistComplete_#{@name}", '', expires: true)

  @delayComplete: =>
    if result = getCookie('abbaDelayComplete')
      [name, value] = result.split('#')
      new this(name).requestComplete(value)
      setCookie('abbaDelayComplete', '', expires: true)

do ->
  # Find Abba's endpoint from the script tag
  scripts = document.getElementsByTagName('script')
  scripts = (script.src for script in scripts when /\/abba\.js$/.test(script.src))
  Abba.endpoint = "//#{host(scripts[0])}" if scripts[0]

bind(window, 'load', Abba.delayComplete)