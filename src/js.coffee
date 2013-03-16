String::trim ?= ->
    String(this).replace(/^\s+|\s+$/g, '')

Math.sign ?= (x) ->
    if x > 0
        1
    else if x < 0
        -1
    else
        0

Array::removeRandom ?= ->
    @splice(Math.floor(ROT.RNG.getUniform() * @length), 1)[0]

Array::remove ?= (item) ->
    while (i = @indexOf(item)) != -1
        @splice(i, 1)
    return
