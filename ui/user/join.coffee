iferr = require 'iferr'
{ View } = require 'backbone'
randword = require 'secure-randword'
request = require 'bitrated-lib/request'
{ user_url } = require 'bitrated-lib/user'
require 'jquery-serializeForm'
{ prepare_keys } = require '../../lib/auth/keys'
Auth = require '../../lib/auth'
User = require '../../model/user'
PasswordView = require './join/password'

SEED_LEN = 16

class JoinView extends View
  events: ->
    'submit form': (e) -> @emit 'submit', e
    'click .gen-pass': 'gen_pass'

  initialize: ->
    super

    require('../../lib/form-validation')(this)
    require('../../lib/form-submission') this,
      loading_ev: 'stretching'
      loading_label: 'Hardening keys...'
      loaded_ev: 'created'

    @is_trade_invite = !!@$('[name=invite_token]').length

    @on 'submit', (e) =>
      e.preventDefault()

      { username, email, password } = data = @$('form').serializeForm()

      # Check availability prior to key stretching
      @check_availability username, email, iferr @error, (res) =>
        if res.error
          if res.status is 422 and legacy_agent = res.body?.meta?.legacy_agent
            @$ '.legacy-agent-notice'
              .find('.username').text(legacy_agent)
              .end().show()
          return @error request.prep_err res

        # We're all good! Prepare the keys and join
        seed = randword(SEED_LEN).join(' ')

        @emit 'stretching'
        prepare_keys { username, seed, password }, (@emitter 'progress'), iferr @error, (key, subkeys) =>
          @emit 'stretched'
          data.pubkey = key.pub
          data.subkeys = {}
          data.subkeys[name] = subkey.pub for name, subkey of subkeys

          join key, data, iferr @error, @emitter 'created', { password, seed }
    
    @on 'created', ({ password, seed }, auth) =>
      new PasswordView { username: auth.user.username, password, seed }
        .render()
        .on 'confirmed', @emitter 'confirmed', auth

    @on 'confirmed', (auth) =>
      activate auth, iferr @error, =>
        auth.store()
        if @is_trade_invite then document.location = '/trade'
        else document.location = user_url auth.user.username
   
    @on 'error', (err) ->
      if err.name is 'ValidationError' and group = err.meta?.reserved
        if group not in [ 'used', 'special' ]
          el = $('<p>')
            .addClass 'help-block'
            .css 'font-weight': 'bold'
            .html 'If you believe this username should be available, please <a href="contact">contact us</a>.'
          @$('.form-group:has([name=username])').append el
          @once 'submit', -> el.remove()

  gen_pass: -> @$('[name=password]').val randword(5+(Math.random()*3|0)).join(' ')

  check_availability: (username, email, cb) ->
    if @$('input[name=upgrade_token]').length then cb null, {}
    else request.post '/join/availability', { username, email }, cb

  join = (key, data, cb) ->
    if invite_token = data.invite_token
      delete data.invite_token

    user = new User data
    auth = new Auth user, key
    user.save {},
      join: true
      auth: auth
      additional_data: { invite_token } if invite_token?
      error: (model, err) => cb err, model
      success: -> cb null, auth

  activate = (auth, cb) ->
    request.post '/activate'
      .sign auth.key
      .end request.iferr cb, -> cb null

module.exports = JoinView
