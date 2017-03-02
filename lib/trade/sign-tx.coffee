# Trade-specific handling for signing transactions
#
# Handles key stretching and creating the redeem scripts, delegates most of the
# crypto work to sign-multisig

iferr = require 'iferr'
{ UserError } = require 'bitrated-lib/errors'
{ buff_eq } = require 'bitrated-lib/util'
Key = require 'bitrated-lib/cryptocoin/key'
derive = require 'bitrated-lib/cryptocoin/derive'
{ sign_multisig } = require 'bitrated-lib/cryptocoin/multisig'
{ scrub } = require 'bitrated-lib/auth/util'
{ get_trade_hash, create_multisig_script } = require 'bitrated-lib/trade/multisig'
{ stretch_contract } = require '../auth/stretch'

# Sign transaction
sign_tx = ({ auth, password, trade, tx }, progress, cb) ->
  derive_ckey { auth, password, trade }, progress, iferr cb, (ckey) ->
    redeem_script = create_multisig_script trade

    try cb null, sign_multisig ckey, tx, redeem_script
    catch err then cb err

    scrub ckey.priv

# Derive the contract key of `auth` for `trade`
derive_ckey = ({ auth, password, trade }, progress, cb) ->
  stretch_contract auth.key, password, progress, iferr cb, (contract_key) =>
    return cb new UserError 'Invalid password' unless buff_eq auth.user.subkeys.contract, contract_key.pub
    ckey = derive contract_key, get_trade_hash trade, auth.user
    scrub contract_key.priv
    cb null, Key.from_priv ckey

module.exports = sign_tx
