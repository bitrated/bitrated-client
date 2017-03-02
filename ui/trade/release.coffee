iferr = require 'iferr'
{ make_tx_to } = require 'bitrated-lib/trade/tx'
TradeView = require './base'
AuthorizeView = require './release/authorize'
DisputeView = require './release/dispute'
tmpl_signed = require './views/dialog/signed-tx.jade'

class ReleaseView extends TradeView
  template: require './views/item/content/release.jade'
  locals: require 'bitrated-lib/trade/view-locals/release'

  events:
    'click [data-tx-to]': 'init_tx_to'
    'click [data-action=dispute]': 'dispute'

  initialize: ->
    super
    sig_confirmation = ({ title, content, txr }) =>
      $ tmpl_signed {
        @trade, txr, @active_ratings, title, content
        authenticated: @app.auth.user.username
      }
      .appendTo '[role=main]'
      .modal backdrop: 'static'
      .on 'hidden.bs.modal', ->
        $(this).trigger('closed').remove()

    @on 'requested', (txr) =>
      @emit 'prevent_status_reload'
      sig_confirmation
        txr: txr
        title: 'Transaction request sent'
        content: 'Transaction request was sent and is awaiting final approval from the other parties.'
      .on 'closed', => @emit 'allow_status_reload'

    @on 'finalized', (txr) =>
      @emit 'prevent_status_reload'
      sig_confirmation
        txr: txr.toJSON?() or txr
        title: 'Funds released'
        content: '''
          Transaction was succesfully finalized and broadcasted to the Bitcoin network.
          The funds will be released shortly, once the transaction confirms.
        '''
      .on 'closed', -> do location.reload

    @trade.on 'change:disputed change:txs change:users_info', @render

  # Initialize and authorize a transaction paying everything to `role`
  init_tx_to: (e) ->
    role = $(e.target).data 'tx-to'
    @try => @authorize make_tx_to @trade.toObject(), @trade[role]

  # Override display_tx to also handle authorizing txs
  display_tx: (tx, txr) ->
    if @requires_auth txr then @authorize tx, txr
    else super

  # Open dispute
  dispute: ->
    @attach new DisputeView { @trade }
      .render()

  # Authorize the `tx`, possibly associated with the `txr` request
  authorize: (tx, txr) ->
    @attach authorize = new AuthorizeView { auth: @app.auth, @trade, tx, txr }
      .on 'authorized', (signed_tx, finalized) =>
        if finalized
          @trade.finalizeTx signed_tx, iferr @error, @emitter 'finalized'
        else
          @trade.requestTx signed_tx, iferr @error, @emitter 'requested'
      .render()

  # Check if the transaction request `txr` requires the current user to authorize it
  requires_auth: (txr) ->
    username = @app.auth.user.username

    @trade.status isnt 'released' and \
    txr.created_by isnt username and \
    not txr.finalized_by and \
    (username in [ @trade.buyer, @trade.seller ] or (username is @trade.arbiter and @trade.disputed))

module.exports = ReleaseView
