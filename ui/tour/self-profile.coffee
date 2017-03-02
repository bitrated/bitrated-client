intro = require('./runner') [
  intro:     'Welcome to your Bitrated profile. Would you like us to show you around?'
  tooltipClass: 'floating'
  # these two aren't actually working yet
  nextLabel: "Let's go"
  exitLabel: "No thanks"
,
  element: '.profile .banner'
  position: 'bottom'
  intro:    "<p>Great! Let's start with the basics.</p>
             <p>The profile header contains the main metrics you should check when deciding if someone is trustworthy.</p>"
,
  element: '.profile .banner .bitrating'
  position: 'right'
  intro:    "This is the Bitrating score, the primary trust metric used by Bitrated.
             It is calculated based on all account information,
             and will grow over time as you establish your reputation."
  highlightClass: 'scale-hexagon'
,
  element:  '.profile .banner .user-metrics'
  position: 'down'
  intro:    'This area provides additional account metrics, as well as navigation.'
,
  element:  '.profile .banner .user-metrics .reviews'
  position: 'top'
  intro:    'Here you\'ll receive reviews from users you trade with.'
,
  element:  '.profile .banner .user-metrics .vouches'
  position: 'top'
  intro:    'Vouches are a special kind of review that shows a trust relationship between two users.'
,
  element:  '.profile .banner .user-metrics .linked'
  position: 'top'
  intro :    'This page shows your verified accounts from around the web.'
,
  intro :   'Alright'
  tooltipClass: 'floating'
]

intro.oncomplete -> document.location='/settings#tour'
