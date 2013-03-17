onDocumentReady = ->
    if not (seed = queryInt('seed'))?
        seed = Date.now()

    ROT.RNG.setSeed(seed)

    new Game({seed: seed})

$(onDocumentReady)

