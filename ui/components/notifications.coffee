{ View, Collection } = require 'backbone'
reltime = require 'bitrated-lib/reltime'
notification_tmpl = require '../../views/inc/notification.jade'

class NotificationsView extends View
  events:
    'shown.bs.dropdown': -> @emit 'shown'
    'hidden.bs.dropdown': -> @emit 'hidden'

  initialize: ({ @notifications }) ->
    super

    # Notifications is always expected to start out empty,
    # and only have items added to it.

    @notifications.on 'synced', => @$el.addClass 'loaded'
    @notifications.on 'add', (notification) =>
      return unless notification.message # ignore notifications with no textual message

      data = notification.toJSON()
      data.created_at = reltime data.created_at
      @$('.dropdown-menu').prepend notification_tmpl data

    @notifications.on 'add change:unread', @updateUnread

    # Mark all as read when opened
    @on 'shown', @notifications.markAllRead

    # Update highlights when closed
    @on 'hidden', ->
      @notifications.each (notification) =>
        unless notification.get 'unread'
          @$('#notification-'+notification.id).removeClass('unread')

  is_unread_msg = (n) -> n.message and n.get 'unread'
  updateUnread: =>
    count = @notifications.filter(is_unread_msg).length
    @$('.unread-count').text count or ''

module.exports = NotificationsView
