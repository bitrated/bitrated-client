{ Model, Collection } = require 'backbone'

class Log extends Model
  @attrs 'user', 'action', 'text', 'created_at'

class Logs extends Collection then model: Log

module.exports = exports = Log
exports.Log = Log
exports.Logs = Logs
