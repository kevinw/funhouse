rot_dirs = ['up', 'up_right', 'right', 'down_right', 'down', 'down_left', 'left', 'up_left']
rot_dirs[dir] = i for dir, i in rot_dirs

ambientLight = [0, 0, 0]

controls = {
    # numpad
    up:  'up'
    page_up: 'up_right'
    right:  'right'
    page_down: 'down_right'
    down:  'down'
    end: 'down_left'
    left:  'left'
    home: 'up_left'

    # vim wizardry
    h: 'left'
    j: 'down'
    k: 'up'
    l: 'right'

    y: 'up_left'
    u: 'up_right'
    b: 'down_left'
    n: 'down_right'
}

assert = (args...) ->
    console.assert.apply(console, args)

keyMap = {}
for keyName, action of controls
    key = 'VK_' + keyName.toUpperCase()
    assert(key, "unknown key " + keyName)

    direction = rot_dirs[action]
    assert(direction != undefined, "could not find a direction for " + action)

    keyMap[ROT[key]] = rot_dirs[action]

class Entity
    constructor: (@game, @_x, @_y) ->

    getSpeed: -> 100

    getX: -> @_x
    getY: -> @_y


class Player extends Entity
    act: ->
        @game._drawWholeMap()
        @game.engine.lock()
        window.addEventListener('keydown', this)

    handleEvent: (e) ->
        code = e.keyCode
        if code == 13 or code == 32
            @_checkBox()
            return

        # one of numpad directions?
        return if not (code of keyMap)

        e.preventDefault()

        # is there a free space?
        dir = ROT.DIRS[8][keyMap[code]]
        newX = @_x + dir[0]
        newY = @_y + dir[1]
        newKey = newX + "," + newY
        return if not (newKey of @game.map)

        #Game.display.draw(@_x, @_y, Game.map[@_x+","+@_y])
        @_x = newX
        @_y = newY
        #@_draw()

        window.removeEventListener("keydown", this)
        @game.engine.unlock()

    _draw: -> {
        character: '@'
        color: "#ff0"
    }

    _checkBox: ->
        key = @_x + "," + @_y
        if @game.map[key] != "☃"
            alert("There is no box here!")
        else if key == @game.ananas
            alert("Hooray! You found an ananas and won this game.")
            @game.engine.lock()
            window.removeEventListener("keydown", this)
        else
            alert("This box is empty :-(")

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

        new Level()

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
