iferr = require 'iferr'
{ View } = require 'backbone'
{ to_satoshis } = require 'bitrated-lib/cryptocoin/util'
{ ValidationError } = require 'bitrated-lib/errors'

class AgentSettingsView extends View
  events: ->
    'change [name=fees-type]': 'change_fees_type'
    'submit form': 'submit'

  initialize: ->
    super
    @on 'saved', -> toastr.success 'Agent settings saved succesfully.'

    require('../../../lib/form-validation')(this)
    require('../../../lib/form-submission')(this, loading_ev: 'saving', loaded_ev: 'saved')

  change_fees_type: (e) ->
    $el = $ e.target
    type = $el.val()
    
    $el.closest('[data-fees-kind]')
      .removeClass('fees-active-percentage fees-active-fixed fees-active-none')
      .addClass("fees-active-#{ type }")
      
      .find('.required-when-active').attr('required', false).end()
      .find(".fees-type-#{ type } .required-when-active").attr('required', true).end()

  submit: (e) ->
    e.preventDefault()

    auto_accept = @$('[name=auto_accept]').is(':checked')
    fees = {}
    try for kind in [ 'base', 'dispute' ]
      $kind = @$ "[data-fees-kind=#{kind}]"
      get_amount = (name) ->
        return unless val = $kind.find("[name=#{name}]").val()
        try to_satoshis val
        catch err
          throw new ValidationError errors: [ field: name, message: 'Invalid value' ]

      fees[kind] = switch type = $kind.find('[name=fees-type]').val()
        when 'percentage' then {
          type
          percentage: +$kind.find('[name=percentage]').val()
          min: get_amount 'min'
          max: get_amount 'max'
        }
        when 'fixed' then { type, fixed: get_amount 'fixed' }
        when 'none' then { type }
      if fees[kind].min? and fees[kind].max? and +fees[kind].min >= +fees[kind].max
        throw new ValidationError errors: min: 'Minimum amount must be smaller than maximum amount'

    catch err then return @error err

    @emit 'saving'
    @app.auth.user.save { auto_accept, arbitration_fees: fees },
      patch: true
      auth: @app.auth
      success: @emitter 'saved'
      error: (model, err) => @error err

module.exports = AgentSettingsView
