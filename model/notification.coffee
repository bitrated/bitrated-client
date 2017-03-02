{ Model, Collection } = require 'backbone'
request = require 'bitrated-lib/request'

noop = ->

class Notification extends Model
  @attrs 'users', 'unread_by', 'type', 'message', 'meta', 'fresh'
  # There's also a "url" attribute, but it conflicts with Backbone's url() method,
  # so it must be read via `get('url')`.

  urlRoot: '/notification'

  parse: (attrs) ->
    attrs.created_at = new Date attrs.created_at
    attrs

  markRead: (cb=noop) ->
    return cb null unless @get 'unread'
    @set 'unread', false
    request.post @url()+'/read', request.iferr (res) ->
      cb null

  class @Notifications extends Collection
    model: Notification

    markAllRead: (cb=noop) =>
      request.post '/notification/read', request.iferr cb, =>
        @each (n) -> n.set 'unread', false
        cb null

    @syncFrom: (ws) =>
      notifications = new this
      ws.on 'notification', (n) -> notifications.add n, parse: true
      ws.once 'notification', -> notifications.emit 'synced'
      notifications


Notification.Notification = Notification
module.exports = Notification
