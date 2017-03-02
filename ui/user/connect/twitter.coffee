{ View } = require 'backbone'
Ladda = require 'ladda-bootstrap'
iferr = require 'iferr'
{ throttle } = require 'bitrated-lib/util'
{ user_url } = require 'bitrated-lib/user'
{ ValidationError } = require 'bitrated-lib/errors'
addr = require 'bitrated-lib/cryptocoin/addr'
request = require 'bitrated-lib/request'

TIMEOUT = 300000 # 5 minutes
AUTOCHECK_INTERVAL = 10000

class TwitterConnectView extends View
  events:
    'submit [data-action=share]': 'share'

  initialize: ->
    super

    @check = @check.bind this
    @btn = @$('button[type=submit]')
    @btn.data 'orig-text', @btn.text()
    @ladda = Ladda.create @btn[0]

    @on 'error', ->
      @btn.find('.ladda-label').text @btn.data('orig-text')
      @ladda.stop()
    @on 'linked', -> document.location = '/connect?linked=twitter'

    require('../../../lib/form-validation')(this)

  share: (e) ->
    e.preventDefault()
    do @stop
    @ladda.start()

    @twtt_username = username = @$('input[name=username]').val().replace /^@/, ''

    # Try connecting to account first, to make sure it exists
    connect username, iferr @error, (res) =>
      if res.error
        if res.body?.code is 'USER_NOTFOUND'
          return @error ValidationError errors: username: 'Twitter username not found'
        unless res.body?.code is 'TWEET_NOTFOUND'
          return @error request.prep_err res
      else return @emit 'linked'

    # This used to be inside the callback, after everything is verified,
    # but then the popup is blocked. We now open the popup while checking
    # the username.
    message = make_message @app.auth.user
    url = user_url @app.auth.user.username

    @btn.find('.ladda-label').text('Waiting for tweet...')

    win = window.open (twitter_share_url message + ' ' + url), 'tweet-connect', 'height=300,width=550,resizable=1'

    $(window).on 'focus', @check
    @timer = setInterval @check, AUTOCHECK_INTERVAL
    setTimeout @stop, TIMEOUT

  check: throttle 2000, ->
    connect @twtt_username, iferr @error, (res) =>
      @emit 'linked' unless res.error

  stop: =>
    clearInterval @timer
    $(window).off 'focus', @check
    @ladda.stop()
    @btn.find('.ladda-label').text @btn.data('orig-text')

  # duplicated in bitrater-server, should be kept in sync
  make_message = (user) -> "
    I'm #{ user.username } on @Bitrated
    (SIN: #{ addr.encode 'SIN', 'ephemeral', user.pubkey })."

  twitter_share_url = (message) ->
   'https://twitter.com/intent/tweet?text='+encodeURIComponent(message)

  connect = (username, cb) -> request.post '/connect/twitter', { username }, cb

module.exports = TwitterConnectView
