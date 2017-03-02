{ Model } = require 'backbone'
iferr = require 'iferr'
bufferify = require 'backbone-bufferify'
request = require 'bitrated-lib/request'
{ field_sighash } = require 'bitrated-lib/auth/sighash'
{ SIGNED_FIELDS } = require 'bitrated-lib/user'

class User extends Model
  urlRoot: '/'
  idAttribute: 'username'

  @attrs 'username', 'pubkey', 'subkeys', 'pubkey_sin', 'arbitration_fees', 'roles', 'default_addresses'

  parse: (attrs) ->
    attrs = super
    if attrs.subkeys? then for k, v of attrs.subkeys when not Buffer.isBuffer v
      attrs.subkeys[k] = new Buffer v, 'hex'
    attrs

  toJSON: (opt) ->
    attrs = super
    if attrs.subkeys? and not opt?.keep_buff
      for k, v of attrs.subkeys
        attrs.subkeys[k] = v.toString('hex')
    attrs

  bufferify this, pubkey: 'hex'

  sync: (method, model, options) ->
    throw new Error 'Cannot sync without auth' unless key = options.auth?.key

    if options.join
      options.method = 'create'
      options.url = '/join'
      changed_attrs = options.attrs or model.attributes
    else
      changed_attrs = options.attrs or model.changed

    options.headers = 'X-Attr-Signatures': attr_sigs @id, key, changed_attrs

    super

  # Load by username or pubkey
  @load: (id, cb) ->
    id = id.toString 'hex' if Buffer.isBuffer id
    request "/#{encodeURIComponent id}", iferr cb, (res) ->
      if res.notFound then cb null
      else if res.error then cb res.error
      else if not res.header['x-is-user'] then cb null
      else cb null, new User res.body, parse: true

  attr_sigs = (username, key, attrs) ->
    sigs = {}
    for k in SIGNED_FIELDS when k of attrs
      v = if k is 'email' then attrs[k].toLowerCase() else attrs[k]
      sigs[k] = key.sign(field_sighash username, k, v).toString('base64')
    JSON.stringify sigs

module.exports = User
