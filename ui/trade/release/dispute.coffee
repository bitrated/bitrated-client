{ View } = require 'backbone'
iferr = require 'iferr'
{ get_amount_display } = require 'bitrated-lib/trade'

class DisputeView extends View
  template: require '../views/dialog/dispute.jade'
  events:
    'submit form': 'submit'
    'hidden.bs.modal': -> @emit 'hidden'

  initialize: ({ @trade }) ->
    super

    @on 'hidden', => @$el.remove()
    @on 'saved', =>
      do @close
      toastr.success "Dispute was created succesfully. The trust agent, #{ @trade.arbiter } was notified.", 'Dispute opened'
    
    require('../../../lib/form-submission')(this, loading_ev: 'saving', loaded_ev: 'saved')

  render: ->
    @setElement @template
      dispute_fee: @trade.arb_fees.dispute
      format_amount: (amount) => get_amount_display { amount, currency: @trade.currency }
    @$el.modal()
    this

  close: -> @$el.modal 'hide'

  submit: (e) ->
    e.preventDefault()
    @emit 'saving'
    message = @$('[name=message]').val()
    @trade.dispute @app.auth, message, iferr @error, @emitter 'saved'

module.exports = DisputeView
