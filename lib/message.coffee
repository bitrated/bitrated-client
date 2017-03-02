message_view = require '../views/dialog/message.jade'

show_message = ({ type, title, message, modal }) ->
  $ message_view { type, title, message }
    .modal(modal or {})
    .on 'hidden.bs.modal', -> $(this).trigger('closed').remove()

show_error = ({ title, message, modal }) ->
  show_message { type: 'error', title: (title or 'Error occurred'), message, modal }

module.exports = { show_message, show_error }
