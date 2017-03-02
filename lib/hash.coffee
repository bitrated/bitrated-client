qs = require 'querystring'

# Parse location hash into an object
parse_hash = -> qs.parse document.location.hash.substr 1

# Clear current page hash from URL
clear_hash = ->
  if history?.replaceState
    # Use history.replaceState when available, to also remove the "#" sign from
    # the URL
    history.replaceState {}, document.title, document.location.pathname
  else
    # Otherwise, simply clear location.hash, which keeps the "#" sign in the
    # URL
    document.location.hash = ''

module.exports = { parse_hash, clear_hash }
