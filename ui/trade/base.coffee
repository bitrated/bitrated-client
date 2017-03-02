{ View } = require 'backbone'
iferr = require 'iferr'
markdown = require 'bitrated-lib/markdown'
request = require 'bitrated-lib/request'
{ extend } = require 'bitrated-lib/util'
{ get_amount_display, get_perspective } = require 'bitrated-lib/trade'
{ deserialize_tx } = require 'bitrated-lib/trade/tx'
{ clear_hash } = require '../../lib/hash'
Trade = require '../../model/trade'
TradeRatingView = require './rating-popover'
TransactionView = require './release/tx'
contract_tmpl = require './views/dialog/contract.jade'
logs_tmpl = require './views/item/inc/log.jade'

class TradeView extends View
  events:
    'click [href=#contract]': 'display_contract'
    'click [data-ntxid]': 'open_tx'
    'click [data-rate]': 'rate'

  initialize: ->
    super

    @trade = new Trade @$('[data-trade]').data('trade'), parse: true
    @active_ratings = @$('[data-active-ratings]').data('active-ratings')

    @on 'attached', (app) ->
      @trade.syncFrom app.notifications

    # Status changes cause a full page refresh
    @trade.on 'change:status', =>
      unless @__prevent_status_reload
        return do location.reload
      # if status reload is prevented, wait until the block is lifted
      @once 'allow_status_reload', -> do location.reload

    # Re-render logs on changes
    @trade.on 'change:logs', @render_logs

    # Display success message for last action taken by the user
    if message = messages[location.hash.substr 1]
      $ '<div>'
        .addClass 'bs-callout bs-callout-info'
        .text message
        .insertBefore @$('.trade-body')
      # Clear hash to prevent the message from popping up when sharing the page URL
      clear_hash()

    # Handle prevent_status_reload state
    @on 'prevent_status_reload', => @__prevent_status_reload = true
    @on 'allow_status_reload', => @__prevent_status_reload = false

  render: =>
    @$('.trade-content').html @template @locals @app.auth.user.id, @trade
    this

  render_logs: =>
    @$('.trade-log').html logs_tmpl @locals @app.auth.user.id, @trade
    this

  # Display the trade contract
  display_contract: (e) ->
    e.preventDefault()
    $ contract_tmpl extend @trade.toJSON(), { markdown }
      .modal()

  # Save user rating
  rate: (e) ->
    e.preventDefault()
    $el = $ e.currentTarget
    target = $el.data('rate')
    value = $el.data('rating')
    comment = @active_ratings[target]?.comment

    $el.addClass('active').siblings('.active,.syncing').removeClass('active syncing')

    @curr_rating?.close()
    @curr_rating = @attach new TradeRatingView { @trade, target, value, comment, container: e.currentTarget }
      .on 'saving', ->
        $el.addClass 'syncing'
      .on 'saved', (rating) =>
        $el.removeClass 'syncing'
        @active_ratings[target] = rating

        # When made using a widget outside of the sidebar (i.e. in the
        # post-authorize dialog), update the sidebar as well.
        unless $el.closest('.trade-sidebar').length
          @$(".trade-sidebar .rate [data-rate=#{target}][data-rating=#{value}]")
            .addClass('active')
            .siblings('.active').removeClass('active')

      .render()

    unless @active_ratings[target]?.value is value
      @curr_rating.save comment

  # Open tx dialog
  open_tx: (e) ->
    ntxid = $(e.target).data 'ntxid'
    txr = @trade.txs.get ntxid
    unless txr
      return @error new Error "Missing txr on #{ @trade.id }, ntxid: #{ ntxid }"
    tx = deserialize_tx txr.rawtx
    @display_tx tx, txr

  # Display transaction information
  display_tx: (tx, txr) ->
    @attach new TransactionView { @trade, tx, txr }
      .render()

  format_amount: (amount) => get_amount_display { currency: @trade.currency, amount }

messages =
  created: 'Trade was succesfully created. The other parties were notified, the trade will begin once they accept it.'
  accepted: 'Trade was succesfully accepted. The other parties were notified.'
  rejected: 'Trade was succesfully rejected. The other parties were notified.'

module.exports = TradeView
