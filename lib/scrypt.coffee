url = process.env.URL
ver = process.env.CLIENT_HEAD

# async scrypt signing via web worker
module.exports = (key, salt, args..., progress, cb) ->
  worker = new Worker url + '/workers/scrypt.js?'+ver

  worker.onerror = (err) ->
    do worker.terminate
    cb err

  worker.onmessage = (e) ->
    obj = JSON.parse e.data
    switch obj.type
      when 'error' then cb new Error obj.err
      when 'progress' then progress obj.state
      when 'result'
        do worker.terminate
        cb null, new Buffer obj.result, 'base64'

  worker.postMessage JSON.stringify [ key.toString('base64'), salt.toString('base64'), args... ]
