String::trim ?= ->
    String(this).replace(/^\s+|\s+$/g, '')

Math.sign ?= (x) ->
    if x > 0
        1
    else if x < 0
        -1
    else
        0
