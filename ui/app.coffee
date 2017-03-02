{ View } = require 'backbone'
require './backbone-extras'
request = require 'bitrated-lib/request'
Auth = require '../lib/auth'
{ Notifications } = require '../model/notification'
NotificationsView = require './components/notifications'

require './common'

dev_mode = process.env.NODE_ENV is 'development'

class App extends View
  initialize: ->
    super

    @auth = Auth.load()
    @ws = Primus.connect process.env.URL if @auth

    # Generic error handler
    @on 'error', (err) ->
      message = err.public and (err.message ? err?.toString()) or 'Unexpected error occurred'
      toastr.error message
      request.post("/report", { err, message: ''+err, stack: err?.stack }).end()
      throw err if dev_mode

    # Keep a reference to app on all child views, recursively
    @on 'attach', ref_app = (child) =>
      child.app = this
      child.on 'attach', ref_app

    # Notifications
    if @auth
      @notifications = Notifications.syncFrom(@ws)
      @notifications.on 'add', (notification) =>
        @emit 'notification:'+notification.get('type'), notification
      @attach new NotificationsView { @notifications, el: $ '.notifications' }

module.exports = App
