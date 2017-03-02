TradeView = require './base'

class NoopView extends TradeView
  template: require './views/item/content/noop.jade'
  locals: require 'bitrated-lib/trade/view-locals/noop'

  initialize: ->
    super
    @trade.on 'change:users_info', @render

module.exports = NoopView
