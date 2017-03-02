iferr = require 'iferr'
{ View } = require 'backbone'
request = require 'bitrated-lib/request'
{ normalize_tags, normalize_addresses } = require 'bitrated-lib/user'
require 'jquery-serializeForm'

class SettingsView extends View
  events: ->
    'submit form': 'submit'
    'change .profile-image input': 'upload_image'
    'click [role=delete-image]': 'delete_image'

  initialize: ->
    super

    require('../../lib/form-validation')(this)
    require('../../lib/form-submission')(this, loading_ev: 'saving', loaded_ev: 'saved')

    @on 'saved', -> toastr.success 'Account settings saved successfully.'

    @on 'image:changed', -> toastr.success 'New image uploaded'
    @on 'image:deleted', -> toastr.success 'Custom image deleted'
    @on 'image:changed image:deleted', ->
      img = @$('.profile-image img')[0]
      img.src = img.src.replace /(\?.*)?$/, '?'+Date.now()

  submit: (e) ->
    e.preventDefault()
    { user } = @app.auth

    #if ($image = @$ '[name=image]')[0].files.length
    #  user.set image: $image[0].files[0]

    @emit 'saving'
    data = @$('form').serializeForm()
    data.roles ?= []
    data.email_lists ?= []
    data.tags = normalize_tags data.tags
    data.default_addresses = normalize_addresses data.default_addresses

    user.save data,
      patch: true
      auth: @app.auth
      success: @emitter 'saved'
      error: (model, err) => @error err

  upload_image: (e) ->
    file = e.target.files[0]
    request.put "/#{ @app.auth.user.id }.png"
      .attach 'image', file
      .end request.iferr @error, @emitter 'image:changed'

  delete_image: (e) ->
    e.preventDefault()
    request.del "/#{ @app.auth.user.id }.png"
      .end request.iferr @error, @emitter 'image:deleted'

module.exports = SettingsView
