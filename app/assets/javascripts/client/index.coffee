# Utils

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

  value  = (value + '').replace(/[^!#-+\--:<-\[\]-~]/g, encodeURIComponent)
  cookie = encodeURIComponent(name) + '=' + value

  cookie += ';expires=' + options.expires.toGMTString() if options.expires
  cookie += ';path=' + options.path if options.path
  cookie += ';domain=' + options.domain if options.domain
  document.cookie = cookie

getCookie = (name) ->
  cookies = document.cookie.split('; ')
  for cookie in cookies
    index = cookie.indexOf('=')
    key   = decodeURIComponent(cookie.substr(0, index))
    value = decodeURIComponent(cookie.substr(index + 1))
    return value if key is name
  null

extend = (target, args...) ->
  for source in args
    for key, value of source when value?
      target[key] = value
  return target

# Public

class @Abba
  endpoint: 'http://localhost:4567'
  defaults:
    path: '/'
    expires: 600

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

  variant: (name, options, callback) ->
    if typeof name isnt 'string'
      throw new Error('Variant name required')

    if typeof options isnt 'object'
      callback = options
      options  = {}

    options.name     = name
    options.callback = callback
    options.weight  ?= 1

    @variants.push(options)
    this

  control: (name = 'Control', options, callback) ->
    if typeof options isnt 'object'
      callback = options
      options  = {}

    options.control = true
    @variant(name, options, callback)

  continue: ->
    # Use the same variant as before, don't record anything
    if variant = @getPreviousVariant()
      @useVariant(variant)
    this

  start: (name, options = {}) ->
    if variant = @getPreviousVariant()
      # Use the same variant as before, don't record anything
      @useVariant(variant)
      return this

    if name?
      # Custom variant provided
      variant = @getVariantForName(name)
      variant or=
        name:    name
        control: options.control

    else
      # Or choose a weighted random variant
      totalWeight   = 0
      totalWeight  += v.weight for v in @variants
      randomWeight  = Math.random() * totalWeight
      variantWeight = 0

      for variant in @variants
        variantWeight += variant.weight
        break if variantWeight >= randomWeight

    throw new Error('No variants added') unless variant
    @recordStart(variant)
    @useVariant(variant)
    this

  complete: (name) ->
    # Optionally pass a name, or read from the cookie
    name or= @getVariantCookie()
    return this unless name

    # If the test has already been completed, return
    return this if @hasPersistCompleteCookie()

    # Persist forever or reset test
    if @options.persist
      @setPersistCompleteCookie()
    else
      @reset()

    @recordComplete(name)
    this

  reset: ->
    @removeVariantCookie()
    @removePersistCompleteCookie()
    @result = null
    this

  # Private

  getVariantForName: (name) ->
    (v for v in @variants when v.name is name)[0]

  useVariant: (variant) ->
    variant?.callback?()
    @chosen = variant

  recordStart: (variant) ->
    # Record which experiment was run on the server
    request(
      "#{@endpoint}/start",
      experiment: @name,
      variant:    variant.name,
      control:    variant.control or false
    )

    # Set the variant we chose as a cookie
    @setVariantCookie(variant.name)

  recordComplete: (name) ->
    # Record the experiment was completed on the server
    request("#{@endpoint}/complete", experiment: @name, variant: name)

  # Variant Cookie

  getPreviousVariant: ->
    if name = @getVariantCookie()
      @getVariantForName(name)

  getVariantCookie: ->
    @getCookie("abbaVariant_#{@name}")

  setVariantCookie: (value) ->
    @setCookie("abbaVariant_#{@name}", value, expires: @options.expires)

  removeVariantCookie: ->
    @setCookie("abbaVariant_#{@name}", '', expires: true)

  # Complete Cookie

  setPersistCompleteCookie: ->
    @setCookie("abbaPersistComplete_#{@name}", '1', expires: @options.expires)

  hasPersistCompleteCookie: ->
    !!@getCookie("abbaPersistComplete_#{@name}")

  removePersistCompleteCookie: ->
    @setCookie("abbaPersistComplete_#{@name}", '', expires: true)

  setCookie: (name, value, options = {}) ->
    setCookie(name, value, extend({}, @defaults, options))

  getCookie: (name, options = {}) ->
    getCookie(name, extend({}, @defaults, options))

do ->
  # Find Abba's endpoint from the script tag
  scripts = document.getElementsByTagName('script')
  scripts = (script.src for script in scripts when /\/abba\.js$/.test(script.src))
  Abba.endpoint = "//#{host(scripts[0])}" if scripts[0]
