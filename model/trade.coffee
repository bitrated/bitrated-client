{ Model } = require 'backbone'
iferr = require 'iferr'
request = require 'bitrated-lib/request'
{ extend } = require 'bitrated-lib/util'
{ get_trade_pubkey } = require 'bitrated-lib/trade/multisig'
trade_sig_message = require 'bitrated-lib/trade/sig-message'
{ Transactions } = require './trade/tx'
{ Outputs } = require './trade/output'
{ UsersInfo } = require './trade/userinfo'
{ Logs } = require './trade/log'

class Trade extends Model
  urlRoot: '/trade'
  @attrs 'currency', 'amount', 'description', 'contract', 'status', 'disputed', 'disputed_by',
         'buyer', 'seller', 'arbiter', 'arb_fees', 'multisig',
         'users_info', 'outputs', 'txs', 'logs', 'meta', 'chaincode'

  collections = outputs: Outputs, txs: Transactions, users_info: UsersInfo, logs: Logs
  
  initialize: ->
    # Trigger the getters to auto-create the default outputs/txs
    # if they don't exists yet
    @[k] for k of collections
    return

  # Parse sub-collections
  parse: (attrs) ->
    for k of collections when (models = attrs[k])?
      @[k].reset models, parse: true
      delete attrs[k]
    attrs

  # JSONify sub-collections
  toJSON: (opt) ->
    attrs = super
    attrs[k] = attrs[k].toJSON(opt) for k of collections
    attrs

  # Return plain object, but keep buffers as-is
  toObject: -> @toJSON keep_buff: true

  # Auto-create sub-collections the first time they're accessed
  get: (key) ->
    val = super
    if not val? and ctor = collections[key]
      @set key, val = new ctor
      val.on 'change add', =>
        @emit 'change:'+key, this, val
        @emit 'change', this
    val

  accept: (auth, address, cb) ->
    ts = new Date
    attrs = @toJSON()
    pubkey = get_trade_pubkey attrs, auth.user
    msg = trade_sig_message attrs, { user: auth.user.id, ts, address, pubkey }
    sig = auth.key.sign_message msg

    request.post @url()+'/accept', { address, pubkey, ts: +ts, sig }, request.iferr cb, -> cb null

  reject: (message, cb) ->
    request.post @url()+'/reject', { message }, request.iferr cb, -> cb null

  requestTx: (tx, cb) ->
    rawtx = new Buffer tx.serialized or tx.serialize()
    request.post @url()+'/tx/request', { rawtx }, request.iferr cb, ({ body }) =>
      cb null, @txs.add body, parse: true

  dispute: (auth, message, cb) ->
    request.post @url()+'/dispute', { message }, request.iferr cb, ({ body }) =>
      @logs.add body, parse: true
      @disputed_by = auth.user.id
      @disputed = true
      cb null

  finalizeTx: (tx, cb) ->
    rawtx = new Buffer tx.serialized or tx.serialize()
    request.post @url()+'/tx/finalize', { rawtx }, request.iferr cb, ({ body }) =>
      cb null, @txs.set body, parse: true

  goto: (hash) ->
    on_trade = location.pathname is @url()
    location.href = @url() + if hash then '#' + hash else ''
    location.reload() if on_trade # force reload when its just an hash change

  syncFrom: (notifications) ->
    notifications.on 'add', (n) =>
      if n.fresh and n.meta?.trade is @id and n.meta.updates?
        for k, v of n.meta.updates
          if @[k]?.models? then @[k].set v, remove: false, parse: true
          else @[k] = v
      return

  @load: (id, cb) ->
    trade = new Trade { id }
    trade.fetch
      error: (model, err) -> cb err
      success: -> cb null, trade

module.exports = Trade

