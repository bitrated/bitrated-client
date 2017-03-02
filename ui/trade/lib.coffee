iferr = require 'iferr'
User = require '../../model/user'

set_default_address = (auth, currency, address, cb) ->
  User.load auth.user.id, iferr cb, ({ default_addresses }) ->
    (default_addresses ?= {})[currency] = address
    auth.user.save { default_addresses },
      patch: true
      auth: auth
      success: -> cb null
      error: (_, err) => cb err

module.exports = { set_default_address }
