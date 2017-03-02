# Hide address bar
scrollTop = window.pageYOffset or document.compatMode is 'CSS1Compat' and document.documentElement.scrollTop or document.body.scrollTop or 0
if scrollTop <= 1 and not location.hash
  setTimeout (-> window.scrollTo 0, 1), 1

# onready is required because this script is included
# prior to jQuery.
(window.onready||=[]).push ->
  # Click to play video
  $('.vid').click ->
    $(this)
    .addClass 'playing'
    .find('.inner').html '''
      <iframe src="https://player.vimeo.com/video/116507236?title=0&amp;byline=0&amp;portrait=0&amp;color=7A6592&amp;autoplay=1" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe>
    '''

    (window._paq?=[]).push ['trackEvent', 'Video', 'Play']
