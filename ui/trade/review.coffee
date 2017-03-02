iferr = require 'iferr'
waiter = require 'async-waiter'
addr = require 'bitrated-lib/cryptocoin/addr'
{ ValidationError } = require 'bitrated-lib/errors'
User = require '../../model/user'
TradeView = require './base'
{ set_default_address } = require './lib'

class ReviewView extends TradeView
  locals: require 'bitrated-lib/trade/view-locals/review'

  events:
    'submit [role=accept]': 'accept'
    'submit [role=reject]': 'reject'

  initialize: ->
    super
    @on 'accepted', -> @trade.goto 'accepted'
    @on 'rejected', -> @trade.goto 'rejected'

    @on 'error', (err) => err.form = @active_form

    @on 'attached', ->
      User.load @app.auth.user.id, iferr @error, (me) =>
        if address = me.default_addresses?[@trade.currency]
          @$('[name=payment_address]').val address

    require('../../lib/form-validation')(this)
    require('../../lib/form-submission')(this, loading_ev: 'saving', loaded_ev: 'accepted rejected')

  accept: (e) ->
    e.preventDefault()
    @active_form = e.target

    address = @$('[name=payment_address]').val()
    set_as_default = @$('[name=set_address_as_default]').is(':checked')

    unless addr.validate @trade.currency, [ 'public', 'scripthash' ], address
      return @error new ValidationError errors: payment_address: 'Invalid address'

    @emit 'saving'
    waiter (wait) =>
      @trade.accept @app.auth, address, wait()
      if set_as_default
        set_default_address @app.auth, @trade.currency, address, wait()
    , iferr @error, @emitter 'accepted'

  reject: (e) ->
    e.preventDefault()
    @active_form = e.target

    @emit 'saving'
    message = @$('[name=message]').val()
    @trade.reject message, iferr @error, @emitter 'rejected'


module.exports = ReviewView
