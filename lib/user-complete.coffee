qs = require 'querystring'
require 'typeahead.js'
{ user_url } = require 'bitrated-lib/user'
suggestion_tmpl = require '../views/inc/user-suggestion.jade'

module.exports = (field, opt = {}) ->
  field = $ field

  url = '/users?q=%QUERY&exclude_self=1'
  if opt.params
    url += '&' + qs.stringify opt.params

  source = new Bloodhound
    datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value')
    queryTokenizer: Bloodhound.tokenizers.whitespace
    remote:
      url: url
      ajax: accepts: json: 'application/json'
  source.initialize()

  $field = $(field).typeahead {
    minLength: 1
  }, {
    name: 'users'
    source: source.ttAdapter()
    displayKey: 'username'
    templates:
      suggestion: (data) -> suggestion_tmpl Object.create data, user_url: value: user_url
  }
  # Fix tab behaviour when tabbing away from typeahead
  $field.data('ttTypeahead').input.onSync 'tabKeyed', ->
    # wait for a little bit to make sure the previous element is still focused
    # and that the browser's native tab jump didn't kick in
    setTimeout ->
      if $field.is(':focus')
        inputs = $field.closest('form').find(':input:visible')
        inputs.eq(inputs.index($field)+1).focus().select()
    , 20
