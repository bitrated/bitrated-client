{ View } = require 'backbone'
iferr = require 'iferr'
waiter = require 'async-waiter'
require 'jquery-serializeForm'
{ to_satoshis } = require 'bitrated-lib/cryptocoin/util'
{ ValidationError } = require 'bitrated-lib/errors'
{ get_inverse_role } = require 'bitrated-lib/trade'
{ calc_fees, fees_text } = require 'bitrated-lib/trade/arb-fees'
validate = require 'bitrated-lib/trade/validate'
Trade = require '../../model/trade'
User = require '../../model/user'
{ set_default_address } = require './lib'

class NewView extends View
  events:
    'submit form': 'submit'
    'change [name=role]':     (e) -> @emit 'change:role',     $(e.target).val()
    'change [name=amount]':   (e) -> @emit 'change:amount',   $(e.target).val()
    'change [name=currency]': (e) -> @emit 'change:currency', $(e.target).val()
    'change [name=contract]': (e) -> @emit 'change:contract', $(e.target).val()
    'change [name=arbiter]':  (e) -> @emit 'change:arbiter',  $(e.target).val()
    'typeahead:selected [name=arbiter]': (e) -> @emit 'change:arbiter',  $(e.target).val()
    'typeahead:autocompleted [name=arbiter]': (e) -> @emit 'change:arbiter',  $(e.target).val()

  initialize: ->
    super

    # Enable form submission once JS is loaded
    @$('form, :submit').attr('disabled', false)

    @on 'change:role', (role) ->
      @$('form').removeClass('role-buyer role-seller').addClass("role-#{role}")
        .find('[name=description]').focus()

    @on 'change:arbiter change:amount change:currency', update_arb_fees = ->
      return unless username = @$('[name=arbiter]').val()
      
      $data = @$ '.arbiter-data'
      User.load username, iferr @error, (arbiter) =>
        unless arbiter?
          return $data.addClass('error').text 'User not found'
        unless arbiter.roles? and 'arbiter' in arbiter.roles and arbiter.arbitration_fees?.base?
          return $data.addClass('error').text 'This user is not offering arbitration services.'

        if amount = @$('[name=amount]').val()
          amount = to_satoshis amount
          currency = @$('[name=currency]').val()
          arb_fees = calc_fees amount, arbiter.arbitration_fees

          if amount <= +arb_fees.base + +arb_fees.dispute
            $data.addClass('error').html "The trust agent does not accept trades of this amount."
          else $data.removeClass('error').html """<strong>Fees:</strong> #{ fees_text { currency, arb_fees } }."""
        else $data.empty()
    do update_arb_fees

    @on 'change:contract', (val) ->
      @$('[name=contract]')[if val.length then 'addClass' else 'removeClass'] 'not-empty'

    # Default addresses
    default_addresses = null
    @on 'change:currency', (currency) ->
      return unless default_addresses
      @$('[name=payment_address]').val default_addresses[currency] or ''

    @on 'attached', ->
      User.load @app.auth.user.id, iferr @error, (me) =>
        default_addresses = me.default_addresses
        @emit 'change:currency', @$('[name=currency]').val()

    @on 'saved', (trade) ->
      address = @$('[name=payment_address]').val()
      set_as_default = @$('[name=set_address_as_default]').is(':checked')

      waiter (wait) =>
        trade.accept @app.auth, address, wait()
        if set_as_default
          set_default_address @app.auth, trade.currency, address, wait()
      , iferr @error, @emitter 'success', trade

    @on 'success', (trade) -> trade.goto 'created'

    @on 'error', (err) ->
      if err.name is 'ValidationError'
        errors = err.errors
        if errors.arbiter
          @$('.arbiter-data').empty()
        # errors for the "buyer" or "seller" field should be applied
        # on the "other-user" field.
        if errors.buyer or errors.seller
          errors.other_user = errors.buyer or errors.seller
          delete errors.buyer
          delete errors.seller

    require('../../lib/form-validation')(this)
    require('../../lib/form-submission')(this, loading_ev: 'saving', loaded_ev: 'success')
    require('../../lib/user-complete') @$('[name=other_user]')
    require('../../lib/user-complete') @$('[name=arbiter]'), params: role: 'arbiter'

  submit: (e) ->
    e.preventDefault()
    username = @app.auth.user.id

    attrs = prepare_attrs username, @$('form').serializeForm()
    return @error err if err = validate username, attrs
    delete attrs.payment_address # sent later, as part of accept

    @emit 'saving'
    trade = new Trade attrs
    trade.save {},
      auth: @app.auth
      error: (model, err) => @error err, model
      success: @emitter 'saved', trade

prepare_attrs = (user, attrs) ->
  attrs[attrs.role] = user
  attrs[get_inverse_role attrs.role] = attrs.other_user
  attrs.amount = to_satoshis attrs.amount
  delete attrs.role
  delete attrs.other_user
  attrs

module.exports = NewView
