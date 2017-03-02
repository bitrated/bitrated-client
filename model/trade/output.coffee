{ Model, Collection } = require 'backbone'

class Output extends Model
  @attrs 'txid', 'index', 'amount', 'block', 'height', 'spender'

  idParser: ({ txid, index }) ->
    txid = txid.toString('hex') if Buffer.isBuffer txid
    "#{ txid }:#{ index }"

  # Not using backbone-bufferify here because we also need to encode/decode
  # the nested spender object. Easier to just do it manually.
  parse: (attrs) ->
    for obj in [ attrs, attrs.spender ] when obj?
      obj.txid = new Buffer obj.txid, 'hex'
      obj.block = new Buffer obj.block, 'hex' if obj.block?
    attrs

  toJSON: ->
    attrs = super
    for obj in [ attrs, attrs.spender ] when obj?
      obj.txid = obj.txid.toString('hex')
      obj.block = obj.block.toString('hex') if obj.block?
    attrs

class Outputs extends Collection
  model: Output

module.exports = exports = Output
exports.Output = Output
exports.Outputs = Outputs
