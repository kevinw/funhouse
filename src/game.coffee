ambientLight = [0, 0, 0]

class Pedro extends Entity
    act: ->
        x = @game.player.getX()
        y = @game.player.getY()

        passableCallback = (x, y) => (x + "," + y of @game.map)

        astar = new ROT.Path.AStar(x, y, passableCallback, {topology:4})

        path = []

        pathCallback = (x, y) -> path.push([x, y])

        astar.compute(@_x, @_y, pathCallback)

        path.shift()
        if path.length == 1
            @game.engine.lock()
            alert("Game over - you were captured by Pedro!")
        else
            @_x = path[0][0]
            @_y = path[0][1]
        
    _draw: -> {
        character: "P"
        color: "red"
    }

class Game
    display: null
    map: {}
    engine: null
    player: null
    pedro: null
    ananas: null
    actors: []

    constructor: ->
        @display = new ROT.Display {
            fontFamily: "Monaco" # TODO: load font
            fontSize: 22
            spacing: 1.1
        }
        document.body.appendChild(@display.getContainer())

        @_generateMap()

        @engine = new ROT.Engine()
        @addActor(@player)
        @addActor(@pedro)
        @engine.start()

    addActor: (actor) ->
        @engine.addActor(actor)
        @actors.push(actor)

    _generateMap: ->
        digger = new ROT.Map.Digger()
        freeCells = []

        digger.create (x, y, value) =>
            return if value
            key = x+","+y
            @map[key] = "·";
            freeCells.push(key)

        @_generateBoxes(freeCells)

        @player = @_createBeing(Player, freeCells)
        @pedro = @_createBeing(Pedro, freeCells)

        @level = new Level()

        lightPasses = (x, y) =>
            not not @map[x+","+y]# == '·'

        @fov = new ROT.FOV.PreciseShadowcasting(lightPasses, {topology: 4})


    _createBeing: (what, freeCells) ->
        index = Math.floor(ROT.RNG.getUniform() * freeCells.length)
        key = freeCells.splice(index, 1)[0]
        parts = key.split(",")
        x = parseInt(parts[0])
        y = parseInt(parts[1])
        return new what(this, x, y)

    _generateBoxes: (freeCells) ->
        for i in [0..10] by 1
            index = Math.floor(ROT.RNG.getUniform() * freeCells.length)
            key = freeCells.splice(index, 1)[0]
            @map[key] = "☃"
            if i == 0
                @ananas = key # first box contains an ananas

    _drawWholeMap: ->
        reflectivity = (x, y) => @map[x+","+y] == '·' ? 0.3 : 0

        lighting = new ROT.Lighting(reflectivity, {range: 12, passes: 2})
        lighting.setFOV(@fov)
        lighting.setLight(@player.getX(), @player.getY(), [200, 200, 200])

        @lightData = {}
        lighting.compute (x, y, color) =>
            @lightData[x+","+y] = color

        actorKeys = {}
        for actor in @actors
            actorKeys[actor.getX() + "," + actor.getY()] = actor

        for key of @map
            parts = key.split(",")
            x = parseInt(parts[0])
            y = parseInt(parts[1])

            baseColor = if @map[key] then [100, 100, 100] else [50, 50, 50]
            light = ambientLight
            if key of @lightData
                light = ROT.Color.add(light, @lightData[key])

            finalColor = ROT.Color.multiply(baseColor, light);

            actor = actorKeys[key]
            if not actor
                character = @map[key]
                fgColor = finalColor
            else
                drawInfo = actor._draw()
                character = drawInfo.character
                fgColor = ROT.Color.multiply(finalColor, ROT.Color.fromString(drawInfo.color))

            @display.draw(x, y, character, ROT.Color.toRGB(fgColor), null);
        
new Game()
