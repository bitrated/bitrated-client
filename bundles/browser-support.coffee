es5 = not do -> 'use strict'; @
webcrypto = (window.crypto or window.msCrypto)?.getRandomValues?

unless es5 and webcrypto then document.write """
  <style>
  .unsupported-browser{display:block}
  .content,.page-header{display:none}
  </style>
"""
