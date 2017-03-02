{ Model, Collection } = require 'backbone'
bufferify = require 'backbone-bufferify'

class Transaction extends Model
  @attrs 'created_by', 'created_at', 'ntxid', 'rawtx',
         'finalized_by', 'final_txid'

  bufferify this, ntxid: 'hex', rawtx: 'base64', final_txid: 'hex'

  idParser: ({ ntxid }) ->
    if Buffer.isBuffer ntxid then ntxid.toString('hex') else ntxid

class Transactions extends Collection then model: Transaction

module.exports = exports = Transaction
exports.Transaction = Transaction
exports.Transactions = Transactions
