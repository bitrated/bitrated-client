Ladda = require 'ladda-bootstrap'

module.exports = (view, opt={}) ->
  ladda = button = null

  view.on (opt.loading_ev or 'loading'), ->
    button ?= (if opt.button then $(opt.button) else view.$(':submit'))
      .addClass 'ladda-button'
      .attr 'data-style', opt.style or 'expand-left'
      .attr 'data-spinner-size', opt.size or 25

    throw new Error 'cannot find button' unless button.length

    button
      .removeClass 'indicator'
      .find('.glyphicon').remove()
    ladda ?= Ladda.create button[0]
    ladda.start()

    if opt.loading_label
      opt.normal_label ?= button.find('.ladda-label').text()
      button.find('.ladda-label').text opt.loading_label

  view.on (opt.progress_ev or 'progress'), ({ percent }) ->
    ladda.setProgress percent/100

  view.on (opt.loaded_ev or 'loaded'), -> done false
  view.on (opt.error_ev or 'error'), -> done true

  done = (is_err) ->
    return unless ladda # if we somehow get here without the `loading_ev` being fired...
    ladda.stop()
    unless is_err
      button.addClass 'indicator'
      button.prepend "<span class='glyphicon glyphicon-ok'></span> "
    button.find('.ladda-label').text opt.normal_label if opt.normal_label
