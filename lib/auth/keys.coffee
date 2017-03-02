iferr = require 'iferr'
{ ValidationError } = require 'bitrated-lib/errors'
{ buff_eq } = require 'bitrated-lib/util'
Key = require 'bitrated-lib/cryptocoin/key'
User = require  '../../model/user'
Auth = require '../auth'
{ stretch_main, stretch_all } = require './stretch'

# Authenticate user and return Auth instance
login = ({ username, seed }, progress, cb) ->
  seed = seed.replace /^\s+|\s+$/g, ''
  User.load username, iferr cb, (user) ->
    unless user?
      return cb new ValidationError errors: username: 'Invalid username'
    unless user.pubkey?
      return cb new ValidationError errors: username: 'Inactive username'
    stretch_main user.username, seed, progress, iferr cb, (key) ->
      unless buff_eq user.pubkey, key.pub
        return cb new ValidationError errors: seed: 'Invalid password'
      cb null, new Auth user, key

# Prepare keys for a new user
prepare_keys = ({ username, seed, password }, progress, cb) ->
  # Stretch the authentication and authorization keys
  stretch_all username, seed, password, progress, cb

module.exports = { login, prepare_keys }
