module.exports = (view) ->
  submitting = false

  view.on 'error', (err) ->
    return unless err.name is 'ValidationError'
    return if submitting # this should never happen, but just in case (to prevent infinite loops)

    form = if err.form? then $ err.form else view.$('form')

    # Attach custom validation errors to fields
    el = null
    for field, message of err.errors
      message = message.message if message.message? # Mongoose validation errors
      continue unless message
      if (el = form.find "input[name='#{field}']:visible").length
        el[0].setCustomValidity message
        el.one 'change blur keydown', ->
          el[0].setCustomValidity ''
        break # just attach the first error. seems like browsers doesn't handle multiple errors well.

    # Trigger submit to display the custom validation errors,
    # but only when an invalid field is found.
    if el.length then setTimeout ->
      submitting = true
      form.find('[type=submit]:eq(0)').click()
      submitting = false
    , 10

    # Display global error
    toastr.error 'Please check the form and correct the errors.'

    # Prevent it from being handled by the global error handler
    err.stopPropagation = true
