'use strict'

rot_dirs = ['up', 'up_right', 'right', 'down_right', 'down', 'down_left', 'left', 'up_left']
rot_dirs[dir] = i for dir, i in rot_dirs

constants =
    sprintMeleeMultiplier: 2
    sprintDistance: 3
    sprintStepBreathCost: 8
    breathRecoveryStep: 4

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

globalId = 1

class Meter
    constructor: (opts) ->
        for key, val of opts
            @[key] = val

    add: (val) ->
        @value = Math.min(@max or 0, @value + val)
        if @value < 0 then @value = 0
        return @value

    trySubtact: (val) ->
        if @value >= val
            @value -= val
            return true

class Entity
    damage: (opts) ->
        entity = opts.from
        amount = opts.amount

        @level.addStatus('%s damaged %s.'.format(entity.statusDesc(), @statusDesc()))

        if @health.add(-amount) == 0
            @die()

    die: ->
        @level.removeEntity(this)

    makeMeter: (name, opts) ->
        if not opts.value?
            opts.value = opts.max

        @_meters ?= {}
        @_meters[name] = new Meter(opts)

    statusDesc: ->
        this.legendDesc or this.constructor.name

    constructor: (@level, @_x, @_y) ->
        assert(@level)

        @guid = globalId
        globalId += 1

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
    seeInFog: true

class Food extends Item
    char: '%'
    color: 'red'

    bump: (entity) ->
        entity.eatFood?(this)

window.Food = Food

class Stairs extends Entity
    color: 'yellow'
    seeInFog: true
    afterBump: (entity) ->
        entity.climbStairs?(this)

class DownStairs extends Stairs
    char: '>'
    delta: 1
    legendDesc: 'Stairs Down'

class UpStairs extends Stairs
    char: '<'
    delta: -1
    legendDesc: 'Stairs Up'

window.Stairs = Stairs
window.DownStairs = DownStairs
window.UpStairs = UpStairs

class Player extends Entity
    seesMirrors: true
    group: 'players'
    toString: -> '<Player>'
    color: '#ff0'
    char: '@'

    legendDesc: 'You'
    legendProps: [{type: 'bar', meter: 'health', label: 'Self-esteem'},
                  {type: 'bar', meter: 'breath', label: 'Breath', color: '#006633'},
                  {type: 'bar', meter: 'imagination', label: 'Imagination', color: '#880055'}]

    constructor: ->
        super

        @numFoods = 0

        @light = {
            color: [200, 200, 200]
        }

        @health = @makeMeter('health', {max: 100})
        @breath = @makeMeter('breath', {max: 100})
        @imagination = @makeMeter('imagination', {max: 100})

    die: ->
        @level.addStatus('You died.')
        @level.lock()

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

    act: ->
        @level.lock()
        window.addEventListener('keydown', this)

    handleEvent: (e) ->
        code = e.keyCode

        if e.altKey then return

        # one of numpad directions?
        return if not (code of keyMap)

        e.preventDefault()

        # is there a free space?
        dir = ROT.DIRS[8][keyMap[code]]
        if e.shiftKey
            @trySprint(dir[0], dir[1])
        else
            newX = @_x + dir[0]
            newY = @_y + dir[1]
            @tryMoveTo(newX, newY)

        window.removeEventListener("keydown", this)
        @level.unlock()

    melee: (entity) ->
        amount = 6

        if opts?.sprinting
            amount *= constants.sprintMeleeMultiplier

        entity.damage
            amount: amount
            from: this

    tryMoveTo: (x, y, opts) ->
        moveInfo = @level.canMoveTo(x, y)
        if not moveInfo.canMove
            if moveInfo.bump?
                @level.addStatus(moveInfo.bump)
        else if (entities = @level.hostilesAtCell(x, y)).length
            for entity in entities
                @melee(entity, opts)
                break
        else
            @level.moveEntity(this, x, y)
            @breath.add(constants.breathRecoveryStep)
            return true

    trySprint: (x, y) ->
        [sprintX, sprintY] = [x * constants.sprintDistance, y * constants.sprintDistance]
        didMove = false
        while sprintX != 0 or sprintY != 0
            if not @breath.trySubtact(constants.sprintStepBreathCost)
                if not didMove
                    @level.addStatus('You try to sprint, but you\'re out of breath.')
                break

            [dx, dy] = [Math.sign(sprintX), Math.sign(sprintY)]
            [newX, newY] = [@_x + dx, @_y + dy]
            sprintX += -dx
            sprintY += -dy

            if not @tryMoveTo(newX, newY, {sprinting: true})
                break

            didMove = true

    _draw: -> {
        character: '@'
        color: "#ff0"
    }

window.Player = Player

class Monster extends Entity
    hostile: true
    char: "&"
    sightRadius: 5

    legendProps: [{type: 'bar', meter: 'health', label: 'Health'}]

    constructor: ->
        super

        @health = @makeMeter('health', {max: 20})

    attacks: {
        scratch: {
            verb: 'scratches'
            damage: 3
        }
    }

    act: ->
        for entity in @visibleEntities()
            if entity.group == 'players'
                [@lastX, @lastY] = entity.position()
                if Point.distance(entity.position(), @position()) < 2
                    @attack(entity)
                    return

        if @lastX?
            @headTowards(@lastX, @lastY)

    attack: (entity) ->
        if entity?.damage
            entity.damage
                amount: 3
                from: this

    headTowards: (x, y) ->
        passableCallback = (x, y) =>
            @level.canMoveTo(x, y).canMove

        astar = new ROT.Path.AStar(x, y, passableCallback, {topology: 8})

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
