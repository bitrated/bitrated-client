{ View } = require 'backbone'
qruri = require 'qruri'
print_tmpl = require '../views/inc/password-print.jade'

class PasswordView extends View
  template: require '../views/dialog/passwords.jade'

  events:
    'change input[role=disclaimer]': ({ target }) -> @emit 'disclaimer-state', target.checked
    'hidden.bs.modal': -> @emit 'hidden'
    'click [role=print]': 'print'
    'submit': 'confirm'

  initialize: ({ @username, @password, @seed }) ->
    super

    @on 'disclaimer-state', (checked) ->
      @$('[type=submit]').attr 'disabled', not checked

    @on 'hidden', -> @$el.remove()

  print: ->
    qr_uri = qruri "Bitrated credentials for #{ @username } | mnemonic: #{ @seed } | 2FA password: #{ @password }"
    data = { @username, @password, @seed, qr_uri }
    data.static_url = process.env.STATIC_URL
    win = window.open '', 'printer'
    win.document.body.innerHTML = ''
    win.document.write print_tmpl data
    win.print()

  confirm: (e) ->
    e.preventDefault()
    @emit 'confirmed'

  render: ->
    @setElement @template { @username, @password, @seed }
    @$el.modal backdrop: 'static'
    this
  
  close: -> @$el.modal 'hide'

module.exports = PasswordView
