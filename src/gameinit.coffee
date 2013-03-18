onDocumentReady = ->
    if not (seed = queryInt('seed'))?
        seed = Date.now()

    ROT.RNG.setSeed(seed)

    window.game = new Game({seed: seed})

$(onDocumentReady)

