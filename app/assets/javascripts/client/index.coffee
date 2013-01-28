class @Abba
  @endpoint: 'http://localhost:4050'

  constructor: (name, options = {}) ->
    unless name
      throw new Error('Experiment name required')

    # Force constructor
    if this not instanceof Abba
      return new Abba(name, options)

    # Return existing instance if available
    instances = @constructor.instances or= {}
    if existing = instances[name]
      return existing
    else
      instances[name] = this

    @name     = name
    @options  = options
    @variants = []

  variant: (name, callback) ->
    unless name
      throw new Error('Variant name required')

    @variants.push(name: name, callback: callback)
    this

  control: (callback) =>
    @variant('_control', callback)
    this

  a: (callback, name = 'a') =>
    @variant(name, callback)
    this

  b: (callback, name = 'b') =>
    @variant(name, callback)
    this

  c: (callback, name = 'c') =>
    @variant(name, callback)
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
      @request('/start', experiment: @name, variant: variant.name)

      # Set the variant we chose as a cookie
      @setVariantCookie(variant.name)

    variant?.callback()

    this

  complete: (name) =>
    # Optionally pass a name, or read from the cookie
    name or= @getVariantCookie()

    # Record the experiment was completed on the server
    @request('/complete', experiment: @name, variant: name) if name
    @removeVariantCookie()
    this

  reset: =>
    @removeVariantCookie()
    @result = null

  # Private

  getVariantCookie: =>
    @getCookie("abbaVariant_#{@name}")

  setVariantCookie: (value) =>
    expires = new Date
    expires.setTime(expires.getTime() + 5*24*60*60*1000) # 5 days
    @setCookie("abbaVariant_#{@name}", value, expires: expires, path: '/')

  removeVariantCookie: =>
    expires = new Date
    expires.setTime(expires.getTime() - 1)
    @setCookie("abbaVariant_#{@name}", '', expires: expires, path: '/')

  # Utils

  request: (url, params = {}) =>
    # Prevent caching
    params.i = new Date().getTime()
    params   = ("#{k}=#{encodeURIComponent(v)}" for k,v of params).join('&')
    (new Image).src = "#{@constructor.endpoint}#{url}?#{params}"
    true

  setCookie: (name, value, options = {}) =>
    value  = (value + '').replace(/[^!#-+\--:<-\[\]-~]/g, encodeURIComponent)
    cookie = encodeURIComponent(name) + '=' + value
    cookie += ';expires=' + options.expires.toGMTString() if options.expires
    cookie += ';path=' + options.path if options.path
    document.cookie = cookie

  getCookie: (name) =>
    cookies = document.cookie.split('; ')
    for cookie in cookies
      index = cookie.indexOf('=')
      key   = decodeURIComponent(cookie.substr(0, index))
      value = decodeURIComponent(cookie.substr(index + 1))
      return value if key is name
    null