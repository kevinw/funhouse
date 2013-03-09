rot_dirs = ['up', 'up_right', 'right', 'down_right', 'down', 'down_left', 'left', 'up_left']
rot_dirs[dir] = i for dir, i in rot_dirs

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

keyMap = {}
for keyName, action of controls
    key = 'VK_' + keyName.toUpperCase()
    assert(key, "unknown key " + keyName)

    direction = rot_dirs[action]
    assert(direction != undefined, "could not find a direction for " + action)

    keyMap[ROT[key]] = rot_dirs[action]


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

window.Player = Player
