iferr = require 'iferr'
request = require 'bitrated-lib/request'
{ pick } = require 'bitrated-lib/util'
Key = require 'bitrated-lib/cryptocoin/key'
User = require '../model/user'

csrf_token = $('meta[name=csrf-token]').attr('content')

class Auth
  constructor: (@user, @key) ->

  toJSON: ->
    user = pick @user.toJSON(), 'username', 'pubkey', 'subkeys'
    { key: @key.priv.toString('base64'), user }

  store: (cb) -> localStorage.auth = JSON.stringify this

  get_session: (duration, cb) ->
    [ cb, duration ] = [ duration, null ] unless cb?
    request '/session/challenge', request.iferr cb, (res) =>
      data = { ts: res.body.ts, ip: res.body.ip, duration }
      request.post('/session', data).sign(@key).end request.iferr cb, ->
        cb null

  @deserialize: (d) ->
    try
      d = JSON.parse d if typeof d is 'string'
      new Auth (new User d.user, parse: true), (Key.from_priv new Buffer d.key, 'base64')

  @load: ->
    # Authenticated if localStorage exists and the server identifies the cookie
    if localStorage.auth? and $('meta[name=authenticated]').length
      @deserialize localStorage.auth
    # If identified by server but no localStorage exists, do a logout
    else if $('meta[name=authenticated]').length
      document.location = '/logout?_csrf='+csrf_token
      null

module.exports = Auth
