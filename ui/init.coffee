App = require './app'

# Initialize main page view
#
# Usage: (require './ui/init') (require './ui/path/to/view')
module.exports = (view, el) -> $ ->
  app = new App el: $ '[role=main]'
  if view?
    app.attach new view el: el or app.el
