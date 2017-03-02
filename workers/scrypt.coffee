scrypt = require 'scryptsy'

post = (type, obj) ->
  obj.type = type
  postMessage JSON.stringify obj

self.onmessage = (e) ->
  try
    [ key, salt, args... ] = JSON.parse e.data
    key = new Buffer key, 'base64'
    salt = new Buffer salt, 'base64'
    res = scrypt key, salt, args..., (state) -> post 'progress', { state }
    post 'result', result: res.toString('base64')
  catch err then post 'error', err: err.stack or ''+err
  do self.close
