module.exports = (steps) ->
  intro = introJs()

  (window.onready||=[]).push ->
    intro.setOptions
      showStepNumbers: false
      exitOnOverlayClick: false
      showBullets: false
      nextLabel: 'Next'
      prevLabel: 'Prev'
      tooltipSpacing: 11
      steps: steps

    $('body > nav.navbar').removeClass 'navbar-fixed-top'
    style = $(document.createElement 'style').text('body{padding-top:0} body .navbar{margin-bottom:0}').appendTo(document.body)

    intro.onexit ->
      $('body > nav.navbar').addClass 'navbar-fixed-top'
      style.remove()

    intro.start()

  intro
