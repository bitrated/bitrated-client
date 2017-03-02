Key = require 'bitrated-lib/cryptocoin/key'

post = (type, obj) ->
  obj.type = type
  postMessage JSON.stringify obj

self.onmessage = (e) ->
  try
    [ key, data, msg_sig ] = JSON.parse e.data
    key = Key.from_priv new Buffer key, 'base64'
    data = new Buffer data, 'base64'

    if msg_sig
      res = key.sign_message data
    else
      res = key.sign data

    post 'result', result: res.toString('base64')
  catch err then post 'error', err: err.stack or ''+err

  do self.close
