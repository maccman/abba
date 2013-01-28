$ = jQuery

class Controller
  tag: 'div'

  events: {}

  constructor: (@options = {}) ->
    @el  = @el or @options.el or document.createElement(@tag)
    @$el = $(@el)
    @$el.addClass(@className)

  $: (sel) ->
    $(sel, @$el)

  append: (controller) ->
    @$el.append(controller.el or controller)

  html: (controller) ->
    @$el.html(controller.el or controller)

module.exports = Controller