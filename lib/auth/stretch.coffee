BigInt = require 'bigi'
iferr = require 'iferr'
{ sha256 } = require 'crypto-hashing'
{ curve } = require 'bitrated-lib/cryptocoin'
{ scrub } = require 'bitrated-lib/auth/util'
Key = require 'bitrated-lib/cryptocoin/key'
scrypt = require '../scrypt'

AUTHN_KDF = N: Math.pow(2, 14), r: 8, p: 1
CONTRACT_KDF = N: Math.pow(2, 16), r: 8, p: 1

AUTHN_OPS = AUTHN_KDF.p * AUTHN_KDF.N * 2
CONTRACT_OPS = CONTRACT_KDF.p * CONTRACT_KDF.N * 2

SALT_PREFIX = 'Bitrated-Auth'
KEY_LEN = 32

# Create the main authentaction key based on username and seed
stretch_main = (username, seed, progress, cb) ->
  stretch (new Buffer seed, 'utf8'),
          (new Buffer SALT_PREFIX + username.toLowerCase(), 'utf8')
          AUTHN_KDF,
          progress,
          cb

# Create the HD root key for contracts based on auth main key and password
stretch_contract = (key, password, progress, cb) ->
  stretch (new Buffer password, 'utf8'),
          sha256(key.priv),
          CONTRACT_KDF,
          progress,
          cb

# Create main auth key and subkeys based on username, seed and password.
#
# The contract subkey is returned as a public key.
stretch_all = (username, seed, password, progress, cb) ->
  totalOps = AUTHN_OPS + CONTRACT_OPS
  prevOps = 0
  progress = do (progress) -> ({ current }) ->
    current += prevOps
    progress { current, total: totalOps, percent: current/totalOps*100 }

  stretch_main username, seed, progress, iferr cb, (key) ->
    prevOps = AUTHN_OPS
    stretch_contract key, password, progress, iferr cb, (contract_priv) ->
      contract_key = Key.from_pub contract_priv.pub
      scrub contract_priv.priv
      cb null, key, contract: contract_key

# Internal helpers

stretch = (key, salt, opts, progress, cb) ->
  scrypt key, salt, opts.N, opts.r, opts.p, KEY_LEN, progress, iferr cb, (key) ->
    key = pad 32, BigInt.fromBuffer(key).mod(curve.n).toBuffer()
    cb null, Key.from_priv key

pad = (len, buff) ->
  if (n = len-buff.length) > 0
    padding = new Buffer (0 for [1..n])
    Buffer.concat [ padding, buff ]
  else buff

module.exports = { stretch_main, stretch_contract, stretch_all, pad }
