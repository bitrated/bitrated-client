url = process.env.URL
ver = process.env.CLIENT_HEAD

# async ecdsa signing via web worker
sign = (key, data, msg_sig, cb) ->
  worker = new Worker url + '/workers/sign.js?'+ver

  worker.onerror = (err) ->
    do worker.terminate
    cb err

  worker.onmessage = (e) ->
    obj = JSON.parse e.data
    switch obj.type
      when 'error' then cb new Error obj.err
      when 'result' then cb null, new Buffer obj.result, 'base64'
      else cb new Error 'unknown message: '+e.data

    do worker.terminate

  data = new Buffer data unless Buffer.isBuffer data
  worker.postMessage JSON.stringify [ key.toString('base64'), data.toString('base64'), msg_sig ]

module.exports =
  sign: (key, data, cb) -> sign key, data, false, cb
  sign_message: (key, data, cb) -> sign key, data, true, cb
