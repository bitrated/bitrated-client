iferr = require 'iferr'
ProfileView = require '../profile'
request = require 'bitrated-lib/request'
confirm = require '../../../lib/confirm'
enc = encodeURIComponent

class UnlinkView extends ProfileView
  events: ->
    'click .remove-acc': 'removeAccount'

  removeAccount: (e) ->
    e.preventDefault()
    el = $(e.target).closest('[data-provider]')
    provider = el.data('provider')
    provider_id = el.data('provider-id')

    confirm title: 'Are you sure?', message: 'Are you sure you want to unlink this account?', confirm_text: 'Unlink account', =>

      request.del "/#{ enc @username }/linked/#{ enc provider }/#{ enc provider_id }"
        .end request.iferr @error, ->
          location.search = '?removed='+(enc provider)

module.exports = UnlinkView
