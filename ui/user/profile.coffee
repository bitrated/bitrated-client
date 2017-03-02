iferr = require 'iferr'
{ View } = require 'backbone'
{ clear_hash } = require '../../lib/hash'
Rating = require '../../model/rating'
TradeRatingView = require '../trade/rating'

class ProfileView extends View
  events:
    'click [role=add-rating]': 'rate'
    'click [data-action=hide-welcome]': 'hide_welcome'
    'click [data-target="#get-vouched"]': -> _paq.push ['trackEvent', 'sharing', 'get-vouched']

  initialize: ->
    super
    @username = @$('.profile').data('username')

    @on 'vouched rated', (rating) ->
      document.location = rating.url() + '#saved'

    @on 'attached', ->
      @attach new VouchView target: @username, el: @$ '.vouch'
        .on 'saved', @emitter 'vouched'

    if location.hash is '#saved'
      toastr.success "Rating for #{ @username } was saved succesfully."
      do clear_hash

  rate: ->
    @attach new TradeRatingView target: @username
      .render()
      .on 'saved', @emitter 'rated'

  hide_welcome: ->
    @$('.welcome').hide('slow').remove()
    document.cookie='hide_welcome=1; expires='+(new Date Date.now()+50000000).toUTCString()

class VouchView extends View
  events:
    'submit form': 'save'

  initialize: ({ @target })->
    super

    require('../../lib/form-submission') this,
      loading_ev: 'vouching'
      loaded_ev: 'vouched'
      button: @$(':submit')

    #@on 'saved', @remove

  remove: => @$el.remove()

  save: (e) ->
    e.preventDefault()
    value = @$('[name=value]').val()
    comment = @$('[name=comment]').val()

    @emit 'saving'
    rating = new Rating { type: 'vouch', target: @target, value, comment }
    rating.save {},
      key: @app.auth.key
      success: @emitter 'saved'
      error: (model, err) => @error err

module.exports = ProfileView
