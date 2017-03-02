# Browser-specific shims and hacks. Loaded very early, before any libraries.

#
# Add browser/platform CSS classes
#
ua = navigator.userAgent.toLowerCase()
is_safari = /safari/.test(ua) and /applewebkit/.test(ua) and !/chrome/.test(ua)

# Safari version
if is_safari
  if safari_version = ua.match(/\sversion\/(\d+)\./)?[1]
    document.body.className += ' safari'+safari_version

# iOS version
if ios_version = ua.match(/\bcpu\b.*\bos (\d+)_\d+.*\slike mac os x.*applewebkit/)?[1]
  document.body.className += ' ios'+ios_version

# Identify Chrome < 37 on Windows (uses gdi (non-directwrite) font rendering)
else if window.chrome and ~navigator.platform.indexOf('Win') and 0 < +ua.match(/chrome\/(\d+)/)?[1] < 37
  document.body.className += ' chrome-gdi'
