iferr = require 'iferr'
sign_tx = require '../../../lib/trade/sign-tx'
TransactionView = require './tx'

class AuthorizeView extends TransactionView
  template: require '../views/dialog/authorize.jade'

  allow_spent: false

  events:
    'submit form': 'authorize'

  initialize: ({ @auth }) ->
    super
    require('../../../lib/form-submission') this,
      loading_ev: 'authorizing'
      loading_label: 'Hardening key...'
      loaded_ev: 'authorized'

    @on 'authorized', -> do @close

    @on 'rendered', -> @$('[name=password]').focus()

  authorize: (e) ->
    e.preventDefault()

    @emit 'authorizing'
    password = @$('[name=password]').val()
    sign_tx { @auth, password, @trade, tx: @tx.clone() }, (@emitter 'progress'), iferr @error, (signed_tx) =>
      @emit 'authorized', signed_tx, @txr?

  locals: ->
    locals = super
    if @txr
      locals.requested_by = @txr.created_by
      locals.finalizing = true
    locals

module.exports = AuthorizeView
