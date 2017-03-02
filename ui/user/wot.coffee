{ View } = require 'backbone'
request = require 'bitrated-lib/request'

class WotView extends View
  initialize: -> do @render
  render: ->
    $graph = @$ '[data-wot-uri]'
    uri = $graph.data('wot-uri')
    sigma.parsers.json uri,
      container: 'wot-graph'
      settings:
        defaultNodeColor: '#ec5148'

module.exports = WotView
