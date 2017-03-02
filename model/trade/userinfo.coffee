{ Model, Collection } = require 'backbone'
bufferify = require 'backbone-bufferify'

class UserInfo extends Model
  idAttribute: 'user'
  @attrs 'user', 'pubkey', 'address', 'ts', 'sig'

  parse: (attrs) ->
    attrs.ts = new Date attrs.ts
    attrs

  toJSON: ->
    attrs = super
    attrs.ts = +attrs.ts
    attrs

  bufferify this, pubkey: 'hex', sig: 'base64'

class UsersInfo extends Collection
  model: UserInfo

module.exports = exports = UserInfo
exports.UserInfo = UserInfo
exports.UsersInfo = UsersInfo
