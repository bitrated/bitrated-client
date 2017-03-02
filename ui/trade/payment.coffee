TradeView = require './base'
info_link = require 'bitrated-lib/trade/info-link'

class PaymentView extends TradeView
  template: require './views/item/content/payment.jade'
  locals: require 'bitrated-lib/trade/view-locals/payment'

  initialize: ->
    super

    @trade.on 'change:users_info change:outputs', @render
    @trade.outputs.on 'add', (output) =>
      # Notify on newly arrived payments only
      unless output.block?
        txid = output.txid.toString('hex')
        short_txid = txid.substr(0, 14)
        link = info_link @trade.currency, 'tx', txid
        toastr.info """
          Transaction <a href="#{ link }" title="#{ txid }">#{ short_txid }...</a>
          was received with #{ @format_amount output.amount }.
        """, 'Payment received', html: true, timeOut: 10000

module.exports = PaymentView
