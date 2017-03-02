iferr = require 'iferr'
{ View } = require 'backbone'
require 'jquery-serializeForm'
{ user_url } = require 'bitrated-lib/user'
{ login } = require '../../lib/auth/keys'

class LoginView extends View
  events: ->
    'submit form': 'submit'

  initialize: ->
    super

    require('../../lib/form-validation')(this)
    require('../../lib/form-submission') this,
      loading_ev: 'processing'
      loading_label: 'Hardening key...'
      loaded_ev: 'success'

    @on 'success', (auth) =>
      auth.store()
      document.location = @$('input[name=return]').val() or user_url auth.user.username

  submit: (e) ->
    e.preventDefault()
    { username, seed } = @$('form').serializeForm()
    @emit 'processing'
    login { username, seed }, (@emitter 'progress'), iferr @error, (auth) =>
      auth.get_session iferr @error, @emitter 'success', auth
  
module.exports = LoginView
