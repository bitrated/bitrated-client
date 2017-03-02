reltime = require 'bitrated-lib/reltime'
{ throttle } = require 'bitrated-lib/util'
{ user_url } = require 'bitrated-lib/user'
request = require 'bitrated-lib/request'
bitrating_tmpl = require '../views/inc/bitrating-tooltip.jade'

# Common site-wide code, both for guests and authenticated users

# Live update for relative times
setInterval ->
  $('.reltime').each ->
    $this = $ this
    { vaguestr } = reltime.calc $this.attr('datetime'), $this.data('reltime-type')
    $this.text(vaguestr)
, 120000 # 2 minutes

# Initialize Bootstrap components
$ -> $('[data-toggle=popover]').popover()

# Bitrating tooltip
$(document.body).tooltip
  selector: '[data-bitrating-scores]'
  html: true
  container: 'body'
  template: '<div class="tooltip bitrating-tooltip" role="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>'
  title: ->
    $this = $ this
    bitrating_tmpl { user_url, user: username: $this.data('username'), scores: $this.data('bitrating-scores') }

# Add `scroll` class when scrolled
update_scroll = do (body=$ document.body) -> ->
  scrollTop = window.pageYOffset or document.compatMode is 'CSS1Compat' and document.documentElement.scrollTop or document.body.scrollTop or 0
  if scrollTop > 2 then body.addClass 'scroll'
  else body.removeClass 'scroll'
$(window).scroll throttle 150, update_scroll
$ update_scroll

# Report errors to server via Piwik
window.onerror = do ({onerror} = window) -> (err, url, line) ->
  request.post("/report", { url, line, err }).end()
  onerror? err, url, line

# Global settings
toastr.options.positionClass = 'toast-top-right'
toastr.options.timeOut = 7500

# Shim for cross-browser HTML5 form validation API
#
# only load polyfiller.js when we detect missing browser support,
# or when its Safari (whose form validation is heavily broken).
has_form_validation = document.createElement('input').checkValidity?

ua = navigator.userAgent.toLowerCase()
is_safari = /safari/.test(ua) and /applewebkit/.test(ua) and !/chrome/.test(ua)

if is_safari or not has_form_validation
  webshim_url = process.env.STATIC_URL + '/lib/webshim'
  $.ajax
    url: webshim_url + '/polyfiller.js'
    dataType: 'script'
    cache: true
    success: ->
      webshim.setOptions
        basePath: webshim_url+'/shims/'
        extendNative: true
      webshim.polyfill 'forms'

# Piwik stats
_paq = window._paq ?= []
_paq.push ['setTrackerUrl', '/s']
_paq.push ['setSiteId', 1]
_paq.push ['trackPageView']
_paq.push ['enableLinkTracking']
