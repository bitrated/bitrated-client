{ View } = require 'backbone'
{ extend } = require 'bitrated-lib/util'
{ get_amount_display } = require 'bitrated-lib/trade'
{ parse_tx } = require 'bitrated-lib/trade/tx'
infolink = require 'bitrated-lib/trade/info-link'

class TransactionView extends View
  template: require '../views/dialog/tx.jade'

  allow_spent: true

  events:
    'hidden.bs.modal': -> @emit 'hidden'

  initialize: ({ @trade, @tx, @txr }) ->
    super
    @on 'hidden', -> @$el.remove()

  render: ->
    try
      @setElement @template @locals()
      @$el.modal backdrop: 'static'
      @emit 'rendered'
    catch err then return @emit 'error', err

  locals: ->
    locals = parse_tx @trade.toObject(), @tx, @allow_spent

    locals.format_amount = (amount) =>
      get_amount_display { amount, currency: @trade.currency }

    if @txr?.final_txid? then extend locals,
      txid: @txr.final_txid.toString 'hex'
      txinfo_url: infolink @trade.currency, 'tx', @txr.final_txid.toString 'hex'

    locals

  close: -> @$el.modal 'hide'


module.exports = TransactionView
