confirm_view = require '../views/dialog/confirm.jade'

confirm = ({ title, message, confirm_text, cancel_text, modal }, onConfirm) ->
  $ confirm_view { title, message, confirm_text, cancel_text }
    .modal(modal or {})
    .on 'hidden.bs.modal', -> $(this).remove()
    .on 'click', '.confirm', ->
      # $(this).modal 'hide'
      do onConfirm

module.exports = confirm
