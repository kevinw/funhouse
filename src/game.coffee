ambientLight = [0, 0, 0]

class Game
    display: null
    map: {}
    engine: null
    player: null
    pedro: null
    ananas: null
    actors: []

    constructor: ->
        @level = new Level(this)
        document.body.appendChild(@level.display.getContainer())

        [x, y] = @level.findFreeCell('floor')
        @player = new Player(@level, x, y)

        @engine = new ROT.Engine()
        @engine.addActor(@player)
        @engine.start()

    lock: ->
        @level.draw()
        @engine.lock()

    unlock: ->
        @engine.unlock()
        
new Game()
