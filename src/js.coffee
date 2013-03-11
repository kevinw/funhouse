String.prototype.trim ?= ->
    String(this).replace(/^\s+|\s+$/g, '')
