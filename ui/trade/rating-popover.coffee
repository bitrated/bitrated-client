{ View } = require 'backbone'
iferr = require 'iferr'
Rating = require '../../model/rating'

class TradeRatingPopoverView extends View
  template: require './views/inc/rating-popover.jade'
  events:
    'submit form': 'submit'
    'click [role=close]': 'close'
    'keydown textarea': 'keydown'

  initialize: ({ @container, @trade, @target, @value, @comment }) ->
    super
    require('../../lib/form-submission')(this, loading_ev: 'saving', loaded_ev: 'saved')

    @on 'hidden', -> @$el.remove()
    @on 'saving', ->
      $label = @$('.ladda-label')
      $label.data 'original-text', $label.text() unless $label.data('original-text')
      $label.text 'Saving...'
    @on 'saved', ->
      $label = @$('.ladda-label').text 'Saved!'
      @$('textarea').one 'keydown change', =>
        @$('.ladda-button').removeClass('indicator')
          .find('.ladda-label').text @$('.ladda-label').data('original-text')

  render: ->
    popover = $(@container).popover
      placement: 'left'
      trigger: 'focus'
      content: @template { @target, @value, @comment }
      html: true
    .popover 'show'
    .data('bs.popover').tip()
    @setElement popover
    @$('textarea').focus() # `autofocus` attr not working for some reason

    this

  close: => @$el.popover 'destroy'

  submit: (e) ->
    e.preventDefault()
    # @once 'saved', @close
    @save @$('[name=comment]').val()

  save: (comment) ->
    @emit 'saving'
    rating = new Rating { type: 'review', trade: @trade.id, @target, @value, comment }

    rating.save {},
      key: @app.auth.key
      success: @emitter 'saved'
      error: (model, err) => @error err

  keydown: (e) -> do @save if e.ctrlKey and e.keyCode is 13

module.exports = TradeRatingPopoverView
