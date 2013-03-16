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
    'There\'s something sharp in your shoe.'
    'You scratch an itch on your nose.'
    'A frigid breeze ruffles the hair on the back of your neck.'
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
    meleeBreathCost: 6
    breathRecoveryStep: 1
    idleStatusChance: .005

    selfEsteemColor: '#0000aa'

    imaginationColor: '#880055'
    mirrorImaginationCost: 10

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

    keyCode = ROT[key]

    if (direction = rot_dirs[action])?
        keyMap[keyCode] = direction
    else
        keyMap[keyCode] = action

globalId = 1

class Meter
    constructor: (opts) ->
        for key, val of opts
            @[key] = val

    add: (val) ->
        @value = Math.min(@max or 0, @value + val)
        if @value < 0 then @value = 0
        return @value

    trySubtract: (val) ->
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
        amount = opts.amount
        sentence = opts.sentence

        if not sentence?
            entity = opts.from
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

usefunc = (opts) ->
    assert(opts.func)
    for k, v of opts
        if k != 'func'
            opts.func[k] = v
    opts.func._useFunc = true
    opts.func

class Item extends Entity
    useFuncs: -> (this[a] for a of this when this[a]?._useFunc)
    blocksPathFinding: false
    seeInFog: true
    inventoryDesc: -> ''
    drop: usefunc
        label: 'drop'
        func: (inventory) -> inventory.drop(this)

class Pickup extends Item
    bump: (entity) ->
        entity.pickup?(this)

class Food extends Pickup
    statusDesc: -> 'food'
    inventoryDesc: -> 'Some food. Boosts your self-esteem.'
    char: '%'
    color: 'red'
    eat: usefunc
        label: 'eat'
        func: (inventory) ->
            inventory.entity.eatFood(this)
            inventory.remove(this)

window.Food = Food

class WhelkShell extends Pickup
    statusDesc: -> 'whelk shell'
    char: 'W'
    inventoryDesc: ->
        'A sprial shell, the kind you put up to your ear to hear the ocean.'
    constructor: ->
        super
        @imaginationValue = Math.floor(ROT.RNG.getNormal(20, 5))
    listen: usefunc
        label: 'listen'
        func: (inventory) ->
            entity = inventory.entity
            msg = 'You place the shell to your ear, and hear the ocean. '
            msg = msg + statusColor(constants.imaginationColor, '(+%s imagination)'.format(@imaginationValue))
            entity.level.addStatus(msg)
            entity.imagination.add(@imaginationValue)
            inventory.remove(this)

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

    remove: (item) ->
        @items.remove(item)

    drop: (item) ->
        @items.remove(item)
        @entity.level.addStatus('You dropped the %s.'.format(item.statusDesc()))

        [x, y] = [@entity.getX(), @entity.getY()]
        item.setPosition(x, y)
        @entity.level.addEntity(item, x, y, {skipBump:true})

    pickup: (item) ->
        @entity.level.removeEntity(item)
        @items.push(item)

# TODO: more composition, less inheritance, duh
class Player extends Entity
    seesMirrors: true
    group: 'players'
    toString: -> '<Player>'
    color: '#ff0'
    statusDesc: -> 'you'
    char: '@'

    legendDesc: 'You'
    legendProps: [{type: 'bar', meter: 'health', label: 'Self-esteem', color: constants.selfEsteemColor},
                  {type: 'bar', meter: 'breath', label: 'Breath', color: '#667700'},
                  {type: 'bar', meter: 'imagination', label: 'Imagination', color: constants.imaginationColor},
                  {type: 'bar', meter: 'xpMeter', label: ((entity) -> 'Level ' + entity.xplevel), color: '#006633'}]

    constructor: ->
        @inventory = new Inventory(this)

        @numFoods = 0

        @light = {
            color: [200, 200, 200]
        }

        @health = @makeMeter('health', {max: 100})
        @breath = @makeMeter('breath', {max: 100})
        @imagination = @makeMeter('imagination', {value: 20, max: 100})

        @xp = 0
        @xplevel = 1
        @_updateXP()

        super
        
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

        return if not (action = keyMap[code])?

        e.preventDefault()

        if (handler = @['on_' + action])
            window.removeEventListener('keydown', this)
            return handler.call this, (takeTurn) =>
                if takeTurn
                    @level.unlock()
                else
                    window.addEventListener('keydown', this)


        # is there a free space?
        dir = ROT.DIRS[8][action]
        if e.shiftKey
            @trySprint(dir[0], dir[1])
        else
            newX = @_x + dir[0]
            newY = @_y + dir[1]
            @tryMoveTo(newX, newY)

        window.removeEventListener("keydown", this)
        @level.unlock()

    on_show_inventory: (after) ->
        showInventory(@inventory, after)

    melee: (entity) ->
        amount = 6

        if opts?.sprinting
            amount *= constants.sprintMeleeMultiplier

        if not @breath.trySubtract(constants.meleeBreathCost)
            @level.addStatus('You try to hit %s, but you\'re wheezing.'.format(entity.statusDesc()))
        else
            entity.damage
                amount: amount
                from: this
                verb: 'punched'

    tryMoveTo: (x, y, opts) ->
        moveInfo = @level.canMoveTo(x, y)
        if not moveInfo.canMove
            skipBumpMsg = false
            if moveInfo.bumpFunc?
                if moveInfo.bumpFunc(this) is false
                    skipBumpMsg = true
            if not skipBumpMsg and moveInfo.bump?
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
            if not @breath.trySubtract(constants.sprintStepBreathCost)
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
    drawOpts: ->
        jiggle: [ROT.RNG.getUniform() * 4 - 2, ROT.RNG.getUniform() * 4 - 2]

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

    attackStatus: -> ['laughing maniacally', 'giggling', 'chuckling'].random()

    fire: (direction) ->
        startPos = @entity.position()
        # THIS IS ATROCIOUS
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
    char: "C"
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
                if (state = attack.attackStatus?())
                    @state = state
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
