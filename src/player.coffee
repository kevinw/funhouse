'use strict'

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

    # wasd
    w: 'up'
    a: 'left'
    s: 'down'
    d: 'right'
}

keyMap = {}
for keyName, action of controls
    key = 'VK_' + keyName.toUpperCase()
    assert(key, "unknown key " + keyName)

    direction = rot_dirs[action]
    assert(direction != undefined, "could not find a direction for " + action)

    keyMap[ROT[key]] = rot_dirs[action]

class Entity
    constructor: (@level, @_x, @_y) ->
        assert(@level)
        @level.addEntity(this, @_x, @_y)

    moveToLevel: (newLevel, x, y) ->
        assert(newLevel != @level)
        @level.removeEntity(this)
        @level = newLevel
        @_x = x
        @_y = y
        @level.addEntity(this, x, y)

    getSpeed: -> 100

    getX: -> @_x
    getY: -> @_y
    position: -> [@_x, @_y]

    bump: ->

    afterBump: ->

    setPosition: (x, y) ->
        @_x = x
        @_y = y

window.Entity = Entity
class Item extends Entity

class Food extends Item
    char: '%'
    color: 'red'

    bump: (entity) ->
        entity.eatFood?(this)

window.Food = Food

class Stairs extends Entity
    color: 'yellow'
    afterBump: (entity) ->
        entity.climbStairs?(this)

class DownStairs extends Stairs
    char: '>'
    delta: 1

class UpStairs extends Stairs
    char: '<'
    delta: -1

window.Stairs = Stairs
window.DownStairs = DownStairs
window.UpStairs = UpStairs

class Player extends Entity
    seesMirrors: true
    group: 'players'

    eatFood: (food) ->
        @numFoods += 1
        @level.removeEntity(food)
        @level.addStatus('You ate a food.')

    climbStairs: (stairs) ->
        entities = @level.allEntities()
        assert (entities.indexOf(this) != -1)
        @level.switchLevel(stairs.delta)
        if stairs.delta == 1
            @level.addStatus('You tiptoe down the stairs. They creak anyways.')
        else
            @level.addStatus('You climb the stairs.')

    constructor: ->
        super

        @numFoods = 0

        @light = {
            color: [200, 200, 200]
        }

    toString: -> '<Player>'

    color: '#ff0'
    char: '@'

    act: ->
        @level.lock()
        window.addEventListener('keydown', this)

    handleEvent: (e) ->
        code = e.keyCode

        # one of numpad directions?
        return if not (code of keyMap)

        e.preventDefault()

        # is there a free space?
        dir = ROT.DIRS[8][keyMap[code]]
        newX = @_x + dir[0]
        newY = @_y + dir[1]
        @tryMoveTo(newX, newY)

        window.removeEventListener("keydown", this)
        @level.unlock()

    tryMoveTo: (x, y) ->
        moveInfo = @level.canMoveTo(x, y)
        if not moveInfo.canMove
            if moveInfo.bump?
                @level.addStatus(moveInfo.bump)
        else
            @level.moveEntity(this, x, y)

    _draw: -> {
        character: '@'
        color: "#ff0"
    }

window.Player = Player

class Monster extends Entity
    char: "&"
    sightRadius: 5

    act: ->
        for entity in @visibleEntities()
            if entity.group == 'players'
                @follow(entity)

    follow: (entity) ->
        passableCallback = (x, y) =>
            @level.canMoveTo(x, y).canMove

        astar = new ROT.Path.AStar(entity.getX(), entity.getY(), passableCallback, {topology: 8})

        path = []
        astar.compute(@_x, @_y, (x, y) -> path.push([x, y]))
        path.shift()
        if path.length
            @level.moveEntity(this, path[0][0], path[0][1])

    visibleEntities: ->
        @fov ?= @level.createFOV()
        vis = []
        @fov.compute(@_x, @_y, @sightRadius, (x, y, r, visible) =>
            vis = vis.concat(@level.entitiesAtCell(x, y)) if visible)
        vis

window.Monster = Monster

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

