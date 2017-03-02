{ View, Model, Collection } = Backbone = require 'backbone'
request = require 'bitrated-lib/request'
{ extend } = require 'bitrated-lib/util'
require('backbone-attrs').install(Backbone.Model)

# Manually attach jQuery to Backbone, this doesn't work otherwise when used
# with browserify
Backbone.$ = jQuery

# Alias trigger() as emit() for uniformity with NodeJS API
Backbone.Events.emit = Backbone.Events.trigger
Backbone.emit = Backbone.trigger
for k in [ 'Model', 'Collection', 'View', 'Router', 'History' ]
  Backbone[k]::emit = Backbone[k]::trigger

#
# View utilities
#

# Add error() method to views as a shorthand for triggering errors
View::initialize = -> @error = @emitter 'error'

# Add emitter() method, which returns a function that emits on the view
View::emitter = (a...) -> (b...) => @emit a..., b...

# Attach child views to parent views
View::attach = (child) ->
  # Propagate errors up the chain
  @listenTo child, 'error', (err) ->
    @error err unless err.stopPropagation

  # Emit attached on child and attach on parent
  @emit 'attach', child
  child.emit 'attached', this

  child

# Shorthand for replacing HTML contents
View::replace = (html) -> @$el.html(html)

# Run `fn` in try..catch and handle errors
View::try = (fn) ->
  try do fn
  catch err then @error err

# Events inhertience
get_events = (obj) -> obj.events?() or obj.events
{ delegateEvents } = View::
View::delegateEvents = (events) ->
  unless @__inherited_events
    my_events = get_events this
    current = @constructor
    while current = current.__super__?.constructor when parent_events = get_events current::
      for k, v of parent_events when not my_events[k]?
        my_events[k] = v
    @events = my_events
    @__inherited_events = true

  delegateEvents.call this, events


# Add idParser() functionallity to Models
#
# This allows to use an ID that's dynmically created at parse() time
# based on other properties.

Model::parse = (resp) ->
  if @idParser? and (id = @idParser resp)?
    resp[@idAttribute] = id
  resp

Collection::set = do ({ set } = Collection::) -> (models, options) ->
  if idParser = @model::idParser
    idAttr = @model::idAttribute
    for model in [].concat models when (id = idParser model)?
      model[idAttr] = id
  set.call this, models, options

# 
# Model
#

# Alias toObject to toJSON, to match Mongoose
Model::toObject = (opt) -> @toJSON opt

# 
# Sync via Superagent
#
# Note: does not handle emulateJSON and emulateHTTP
Backbone.sync = (method, model, options) ->
  # Initialize request
  req = request method_map[options.method or method],
                options.url or model.url?() or model.url or throw new Error 'Missing URL'

  # PATCH seems to be broken on Chrome 34
  req.set 'X-HTTP-Method-Override', 'PATCH' if method is 'patch'

  # Send data in post or query string
  if method in [ 'create', 'update', 'patch' ]
    data = options.data or options.attrs or model.toJSON(options)
    extend data, options.additional_data if options.additional_data?
    req.send data
  else if options.data?
    req.query options.data

  # Attach headers
  if options.headers
    for name, val of options.headers
      req.set name, val

  # Sign request
  options.key ?= options.auth.key if options.auth?
  req.sign options.key if options.key?

  # Send request
  req.end (err, res) ->
    if err? then options.error? err
    else if res.error then options.error? request.prep_err res
    else options.success? res.body, res

    options.complete? res

  model.trigger 'request', model, req, options

  req

# Backbone method -> HTTP method map
method_map = create: 'post', update: 'put', patch: 'post', delete: 'delete', read: 'get'
