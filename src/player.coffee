'use strict'

rot_dirs = ['up', 'up_right', 'right', 'down_right', 'down', 'down_left', 'left', 'up_left']
rot_dirs[dir] = i for dir, i in rot_dirs

xpForNextLevel = (level) -> 
    Math.ceil(Math.pow(1.6, level) * 3) - 3

for n in [0..10]
    console.log('level to' , n+1, 'at', xpForNextLevel(n))

idleStatuses = [
    'You yawn nervously.'
    'You cringe as loud recorded laughter booms from a hidden speaker.'
]

enemyStates =
    hunting: 'Hunting'

window.constants =
    lightPasses: 1
    playerSightRadius: 20
    playerSpeed: 100
    hahaSpeedMultipler: 2
    sprintMeleeMultiplier: 2
    sprintDistance: 3
    sprintStepBreathCost: 10
    breathRecoveryStep: 1
    idleStatusChance: .01

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

    i: 'show_inventory'
}

keyMap = {}
for keyName, action of controls
    key = 'VK_' + keyName.toUpperCase()
    assert(key, "unknown key " + keyName)

    if (direction = rot_dirs[action])?
        keyMap[ROT[key]] = direction

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

class EventDispatcher
    publish: (eventName, args...) ->
        if (subscribers = @_subscribers)
            if (subscriberList = subscribers[eventName])?
                for subscriber in subscriberList
                    subscriber(args...)

    subscribe: (eventName, cb) ->
        if not (subscriberList = @_subscribers[eventName])
            subscriberList = @_subscribers[eventName] = []
        subscriberList.push(cb)

    unsubscribeAll: ->
        delete @_subscribers

class Entity extends EventDispatcher
    constructor: (@level, @_x, @_y) ->
        assert(@level)

        assert(typeof(@_x) == 'number' and not isNaN(@_x))
        assert(typeof(@_y) == 'number' and not isNaN(@_x))

        @guid = globalId
        globalId += 1

        @level.addEntity(this, @_x, @_y)

    charFunc: (x, y) -> @char

    triggerEffect: (name, value) ->
        @effect ?= {}
        @effect[name] = value

    damage: (opts) ->
        entity = opts.from
        amount = opts.amount

        verb = opts.verb or 'damaged'

        sentence = '%s %s %s.'.format(entity.statusDesc(), verb, @statusDesc())
        sentence = sentence[0].toUpperCase() + sentence.substr(1)

        @level.addStatus(sentence)

        if @health.add(-amount) == 0
            @die()

        @triggerEffect('damage', amount)

    die: ->
        @_dead = true
        @level.removeEntity(this)
        @publish('dead')
        @unsubscribeAll()

    makeMeter: (name, opts) ->
        if not opts.value?
            opts.value = opts.max

        @_meters ?= {}
        @_meters[name] = new Meter(opts)

    statusDesc: ->
        if @legendDesc?
            if @needsThe
                return 'the ' + @legendDesc
            else
                return @legendDesc

        return @constructor.name

    moveToLevel: (newLevel, x, y) ->
        assert(newLevel != @level)
        @level.removeEntity(this)
        @level = newLevel
        @_x = x
        @_y = y
        @level.addEntity(this, x, y, {movingLevels: true})

    getSpeed: -> constants.playerSpeed

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
    blocksPathFinding: false
    seeInFog: true

class Pickup extends Item
    bump: (entity) ->
        entity.pickup?(this)

class Food extends Pickup
    statusDesc: -> 'food'
    char: '%'
    color: 'red'

window.Food = Food

class WhelkShell extends Pickup
    statusDesc: -> 'whelk shell'
    char: 'W'
    constructor: ->
        super
        @imaginationValue = ROT.RNG.getNormal(20, 5)
    use: (entity) ->
        entity.level.addStatus('You place the shell to your ear, and hear the ocean.')
        entity.imagination.add(@imaginationValue)

window.WhelkShell = WhelkShell

class Stairs extends Entity
    color: 'yellow'
    seeInFog: true
    afterBump: (entity, opts) ->
        if opts? and opts.movingLevels
            return
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

class Inventory
    constructor: (@entity) ->
        @items = []

    pickup: (item) ->
        @entity.level.removeEntity(item)
        @items.push(item)

class Player extends Entity
    seesMirrors: true
    group: 'players'
    toString: -> '<Player>'
    color: '#ff0'
    statusDesc: -> 'you'
    char: '@'

    legendDesc: 'You'
    legendProps: [{type: 'bar', meter: 'health', label: 'Self-esteem'},
                  {type: 'bar', meter: 'breath', label: 'Breath', color: '#667700'},
                  {type: 'bar', meter: 'imagination', label: 'Imagination', color: '#880055'},
                  {type: 'bar', meter: 'xpMeter', label: ((entity) -> 'Level ' + entity.xplevel), color: '#006633'}]

    constructor: ->
        super
        
        @inventory = new Inventory(this)

        @numFoods = 0

        @light = {
            color: [200, 200, 200]
        }

        @health = @makeMeter('health', {max: 100})
        @breath = @makeMeter('breath', {max: 100})
        @imagination = @makeMeter('imagination', {max: 100})

        @xp = 0
        @xplevel = 1
        @_updateXP()

    awardXp: (info) ->
        if typeof(info.xp) != 'number'
            console.log("ERROR: expected info.xp to be a number, got " + typeof(info.xp))
            return

        @xp += info.xp
        @_updateXP()

    _updateXP: ->
        lastLevelUp = xpForNextLevel(@xplevel-1)
        nextLevelUpAt = xpForNextLevel(@xplevel)

        originalLevel = @xplevel
        while @xp >= nextLevelUpAt
            @xplevel += 1
            lastLevelUp = xpForNextLevel(@xplevel-1)
            nextLevelUpAt = xpForNextLevel(@xplevel)

        if @xplevel > originalLevel
            @didLevelUp()

        max = nextLevelUpAt - lastLevelUp
        value = @xp - lastLevelUp

        @xpMeter = @makeMeter('xp', {value: value, max: max})

    didLevelUp: ->
        alert("YOU LEVELED UP TO " + @xplevel)

    die: ->
        @level.addStatus('You died.')
        @level.lock()
        super

    eatFood: (food) ->
        @numFoods += 1
        @level.removeEntity(food)
        @level.addStatus('You ate a food.')

    pickup: (item) ->
        @inventory.pickup(item)
        @level.addStatus('You picked up the %s.'.format(item.statusDesc()))

    climbStairs: (stairs) ->
        entities = @level.allEntities()
        assert (entities.indexOf(this) != -1)
        @level.switchLevel(stairs.delta)
        if stairs.delta == 1
            @level.addStatus('You tiptoe down the stairs. They creak anyways.')
        else
            @level.addStatus('You climb the stairs.')

    act: ->
        @level.game.turn += 1
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
            verb: 'punched'

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
            if ROT.RNG.getUniform() < constants.idleStatusChance
                @showIdleStatus()

            return true

    showIdleStatus: ->
        if idleStatuses.length
            @level.addStatus(idleStatuses.removeRandom())

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

class Bullet extends Entity
    blocksPathFinding: false
    seeInFog: true
    hideFromLegend: true
    damageOpts: -> {}
    bump: (entity) ->
        if entity.group == 'players'
            if entity.damage
                opts = extend({
                    amount: 3
                    from: @sourceEntity or this
                }, @damageOpts())
                entity.damage(opts)
                @die()

    act: ->
        target = vector.add(@position(), @velocity)
        @level.moveEntity(this, target[0], target[1])
        if not @level.canMoveTo(@_x, @_y).canMove
            @die()

class HaBullet extends Bullet
    char: '*'
    getSpeed: -> constants.playerSpeed * constants.hahaSpeedMultipler
    damageOpts: ->
        verb: 'laughed at'
    constructor: (level, x, y, @velocity, @sourceEntity) ->
        @origin = [x, y]
        super
    charFunc: (x, y) ->
        if (x + y + @level.game.turn) % 2 is 0 then 'H' else 'A'

class Attack
    constructor: (@entity) ->


class Beam extends Attack
    beamWidth = 3

    fire: (direction) ->
        startPos = @entity.position()
        for n in [1..constants.hahaSpeedMultipler+1]
            startPos = vector.add(direction, startPos)
            otherEntities = (a for a in @entity.level.entitiesAtCell(startPos[0], startPos[1]) when a instanceof HaBullet)
            if otherEntities.length == 0
                new HaBullet(@entity.level, startPos[0], startPos[1], direction, @entity)

    shouldAttack: (entityInfo) ->
        entity = entityInfo.entity

        entityInfo.closestCardinalTo ?= vector.closestCardinal(entityInfo.vectorTo)
        entityInfo.lengthTo ?= vector.length(entityInfo.vectorTo)

        if entityInfo.lengthTo > 3 and entity.getX() == @entity.getX() or entity.getY() == @entity.getY()
            @fire(entityInfo.closestCardinalTo)
            return true


class Monster extends Entity
    needsThe: true
    hostile: true
    char: "&"
    sightRadius: 15
    legendDesc: 'Evil Clown'
    legendProps: [{type: 'bar', meter: 'health', label: 'Health'}]

    xpValue: -> 1

    die: ->
        @level.awardXp
            xp: @xpValue()
        super

    constructor: ->
        super
        @attacks = [new Beam(this)]

        @health = @makeMeter('health', {max: 20})

    attacks: {
        scratch: {
            verb: 'scratches'
            damage: 3
        }
    }

    act: ->
        myPosition = @position()
        for entity in @visibleEntities('players')
            @lastSeenPos = entity.position()

            vectorTo = vector.subtract(@lastSeenPos, myPosition)
            length = vector.length(vectorTo)
            if length < 2
                @attack(entity)
                return
            else
                if @chooseAttack(
                    entity: entity,
                    vectorTo: vectorTo
                )
                    return

        if @lastSeenPos?
            @state = enemyStates.hunting
            @headTowards(@lastSeenPos[0], @lastSeenPos[1])

    chooseAttack: (entityInfo) ->
        for attack in @attacks
            if attack.shouldAttack(entityInfo)
                return true

    attack: (entity) ->
        if entity?.damage
            entity.damage
                amount: 3
                from: this
                verb: ['smacked', 'punched'].random()

    headTowards: (x, y) ->
        passableCallback = (x, y) =>
            @level.canMoveTo(x, y, {entities: true, self: this}).canMove

        astar = new ROT.Path.AStar(x, y, passableCallback, {topology: 8})

        path = []
        astar.compute(@_x, @_y, (x, y) -> path.push([x, y]))
        path.shift()
        if path.length
            @level.moveEntity(this, path[0][0], path[0][1])

    visibleEntities: (inGroup) ->
        @fov ?= @level.createFOV()

        groupTest = if inGroup?
            (e) -> e.group == inGroup
        else
            (e) -> true

        vis = []
        @fov.compute(@_x, @_y, @sightRadius, (x, y, r, visible) =>
            if visible
                entities = (e for e in @level.entitiesAtCell(x, y) when groupTest(e))
                vis = vis.concat(entities)
        )

        vis

window.Monster = Monster
