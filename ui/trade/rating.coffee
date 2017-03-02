{ View } = require 'backbone'
iferr = require 'iferr'
Rating = require '../../model/rating'

class TradeRatingView extends View
  template: require './views/dialog/rating.jade'
  events:
    'submit form': 'save'
    'hidden.bs.modal': -> @emit 'hidden'
    'change form [name=value]': -> @emit 'value-changed'

  initialize: ({ @trade, @target, @value }) ->
    super

    @on 'hidden', -> @$el.remove()
    @on 'value-changed', -> @$('form [name=comment]').focus()
    @on 'saved', @close

    require('../../lib/form-submission')(this, loading_ev: 'saving', loaded_ev: 'saved')

  render: ->
    @loadPrevRating iferr @error, (rating) =>
      rating = if rating then rating.toJSON() else {}
      rating.value = @value if @value?
      @setElement @template { trade: @trade?.toJSON(), @target, rating }
      @$el.modal()
    this

  loadPrevRating: (cb) ->
    if @trade then Rating.loadMineForTrade { trade: @trade.id, @target }, cb
    else cb null

  close: => @$el.modal 'hide'

  save: (e) ->
    e.preventDefault()
    value = @$('[name=value]:checked').val()
    comment = @$('[name=comment]').val()

    @emit 'saving'
    rating = new Rating { type: 'review', trade: @trade?.id, @target, value, comment }

    rating.save {},
      key: @app.auth.key
      success: @emitter 'saved'
      error: (model, err) => @error err

module.exports = TradeRatingView
