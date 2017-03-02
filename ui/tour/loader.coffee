static_url = process.env.STATIC_URL

# like $.getScript, but with a custom version-based cache busting string
# instead of a random one
getScript = (url, cb) ->
  $.ajax
    url: url
    dataType: 'script'
    cache: true
    success: cb

# Load the base introjs library.
load_lib = (cb) ->
  return cb null if introJs?

  getScript '/lib/intro.js/intro.js', cb

  # don't wait for css to finish, only for js
  $(document.createElement 'link')
    .attr rel: 'stylesheet', href: static_url+'/lib/intro.js/introjs.css'
    .appendTo document.body

  if process.env.NODE_ENV is 'development'
    # on production, introjs.css already contains this
    $(document.createElement 'link')
      .attr rel: 'stylesheet', href: static_url+'/tour.css'
      .appendTo document.body

page_tour = $('script[data-page-tour]').data('page-tour')
active_tours = document.cookie.match(/(?:^|; )tours=([^;]+)/)?[1].split(/,/) or []

if (location.hash is '#tour') or (page_tour in active_tours)
  load_lib -> getScript static_url+'/tour/'+page_tour+'.js'

if location.hash is '#tour'
  if history?.replaceState?
    history.replaceState {}, document.title, document.location.pathname
  else document.location.hash = ''
