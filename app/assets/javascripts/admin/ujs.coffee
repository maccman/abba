jQuery ($) ->
  $('body').on 'click', 'a[data-confirm]', (e) ->
    $el = $(e.target)

    unless confirm($el.data('confirm'))
      e.stopImmediatePropagation()
      false

  $('body').on 'click', 'a[data-method]', (e) ->
    e.preventDefault()

    $el = $(e.target)
    $.ajax(
      url: $el.attr('href'),
      type: $el.data('method')
    ).success ->
      window.location.reload()