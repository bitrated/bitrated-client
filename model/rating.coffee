{ Model } = require 'backbone'
iferr = require 'iferr'
request = require 'bitrated-lib/request'
{ rating_sig_message } = require 'bitrated-lib/rating'
{ user_url } = require 'bitrated-lib/user'
{ rating_url } = require 'bitrated-lib/rating'
{ extend } = require 'bitrated-lib/util'
User = require './user'

class Rating extends Model
  @attrs 'type', 'rater', 'target', 'trade', 'value', 'comment', 'role', 'sig'

  url: ->
    if @isNew() then switch @type
      when 'review'
        if @trade then "/trade/#{ @trade }/review/#{ @target }" \
        else "#{ user_url @target }/review"
      when 'vouch'
        "#{ user_url @target }/vouch"
      else throw new Error 'uknown type'
    else rating_url this

  sync: (method, model, options) ->
    throw new Error 'Requires key' unless options.key?
    options.error ?= (err) -> throw err

    User.load @target, iferr options.error, (target) =>
      return options.error new Error 'Non-existent user' unless target?

      process.nextTick =>
        sig = options.key.sign_message rating_sig_message target, this
        delete options.key # don't sign the request, the rating sig is enough

        # non-attached trade ratings are POST create operation, the rest are update PUT operations
        method = if @type is 'review' and not @trade then 'create' else 'update'
        data = { @value, @comment, sig }

        super method, model, extend options, { data }

  @loadMineForTrade: ({ trade, target }, cb) ->
    request "/trade/#{ trade }/reviews/#{ target }/mine", iferr cb, (res) ->
      if res.status is 404 then cb null
      else if res.error then cb reqest.prep_err res
      else cb null, new Rating res.body, parse: true

module.exports = Rating
