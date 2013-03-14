LIGHT_TOPOLOGY = 8
RENDER_MIRRORS = true

KEY = (x, y) ->
    return x + ',' + y

COORDS = (key) ->
    parts = key.split(",")
    x = parseInt(parts[0])
    y = parseInt(parts[1])
    return [x, y]

mirrors =
    leftmirror:
        dx: 1
        dy: 0
    rightmirror:
        dx: -1
        dy: 0
    upmirror:
        dx: 0
        dy: 1
    downmirror:
        dx: 0
        dy: -1

class Level
    constructor: (@game, opts) ->
        opts ?= {}

        @addActor = opts.addActor
        @removeActor = opts.removeActor

        @cells = {}
        @bgs = {}
        @fgs = {}

        @cellsByName = {}
        @entities = {}
        @mirrorSeers = []

        console.time('generating floor')
        @generate(opts)
        console.timeEnd('generating floor')

        @ambientLight = [0, 0, 0]

        @display = @game.display

    canMoveTo: (x, y) ->
        key = KEY(x, y)
        cell = @cells[KEY(x, y)]
        if not cell?
            return false

        if cell.blocksMovement == false
            return {canMove: true}

        bump = getBumpMessage(cell)
        return {canMove: false, bump: bump}

    allEntities: ->
        all = []
        for key, entityList of @entities
            all = all.concat(entityList)

        return all

    entitiesAtCell: (x, y) ->
        return (@entities[KEY(x, y)] or []).slice()

    hostilesAtCell: (x, y) ->
        return (e for e in @entitiesAtCell(x, y) when e.hostile)

    switchLevel: (delta) ->
        @game.switchLevel(delta)

    findFreeCell: ({type, room} = {}) ->
        type ?= 'floor'

        assert(typeof(type) == 'string')

        cellList = @cellsByName[type]
        assert(cellList.length)
        roomRect = if room? then Rect.fromRoom(room)

        while true
            # TODO: bust out of this loop
            key = cellList.random()

            if roomRect?
                [x, y] = COORDS(key)
                if not roomRect.containsXY(x, y)
                    continue

            assert(@cells[key] == cells[type])
            if not @entities[key]?.length
                return COORDS(key)

    lock: -> @game.lock()
    unlock: -> @game.unlock()

    addStatus: (statusMessage) ->
        @game.addStatus(statusMessage)

    setCell: (x, y, type) ->
        cell = cells[type]
        assert(cell, "unknown cell type '%s'".format(type.toString()))
        key = x+','+y

        oldCell = @cells[key]
        if oldCell?
            delete @fgs[key]
            delete @bgs[key]
            cellList = @cellsByName[oldCell.name]
            i = cellList.indexOf(key)
            if i != -1 then cellList.splice(i, 1)

        @cells[key] = cell

        if cell.bg? then @bgs[key] = cell.bg.random()
        if cell.fg? then @fgs[key] = cell.fg.random()

        cellList = @cellsByName[type]
        if not cellList then cellList = @cellsByName[type] = []

        cellList.push(key)

    generate: (opts) ->
        if true
            width = 60#ROT.DEFAULT_WIDTH
            height = ROT.DEFAULT_HEIGHT
            digger = new ROT.Map.Digger(width, height)
            digger.create (x, y, val) =>
                if val == 0
                    @setCell(x, y, 'floor')

            # place walls
            for y in [0..height]
                for x in [0..width]
                    if not @cells[x+','+y]?
                        left = @cells[(x-1)+','+y]
                        right = @cells[(x+1)+'.'+y]
                        if false and @cells[x+','+(y+1)] == cells.floor and (not left or left == cells.downmirror) and (not right or right == cells.downmirror)
                            @setCell(x, y, 'downmirror')
                        else
                            for [dx, dy] in ROT.DIRS['8']
                                if @cells[(x+dx)+','+(y+dy)] == cells.floor
                                    @setCell(x, y, 'plywood')
                                    break

            # place down stairs
            exitRoom = digger.getRooms().random()
            exitRoomRect = Rect.fromRoom(exitRoom)
            [x, y] = @findFreeCell({room: exitRoom})
            @downStairs = new DownStairs(this, x, y)

            # place up stairs in a room kind of far away
            otherRooms = (r for r in digger.getRooms() if r != exitRoom)
            otherRooms.sort (r1, r2) ->
                a = Point.distance(Rect.fromRoom(r1).center(), exitRoomRect.center())
                b = Point.distance(Rect.fromRoom(r2).center(), exitRoomRect.center())
                return if a >= b then -1 else 1

            entranceRoom = otherRooms[0] or exitRoom
            entranceRoomRect = Rect.fromRoom(entranceRoom)
            [x, y] = @findFreeCell({room: entranceRoom})

            if not opts.noUpStairs
                @upStairs = new UpStairs(this, x, y)
            else
                @upStairsPosition = [x, y]

            # place down monsters
            for i in [0..4]
                [x, y] = @findFreeCell()
                while entranceRoomRect.containsXY(x, y)
                    [x, y] = @findFreeCell()
                new Monster(this, x, y)

        else
            [startx, endx] = [7, 23]
            [starty, endy] = [3, 13]

            WALLS_MIRRORED = true

            for y in [starty..endy]
                for x in [startx..endx]
                    @setCell(x, y, 'floor')

            if WALLS_MIRRORED
                for y in [starty..endy]
                    @setCell(endx+1, y, 'leftmirror')
                    @setCell(startx-1, y, 'rightmirror')
                    undefined

                for x in [startx..endx]
                    @setCell(x, endy+1, 'upmirror')
                    @setCell(x, starty-1, 'downmirror')
                    undefined

        @recalcFov()

        for i in [0..9]
            [x, y] = @findFreeCell()
            new Food(this, x, y)

    entryPosition: (delta) ->
        if delta > 0
            @upStairs?.position() or @upStairsPosition
        else
            @downStairs.position()

    _lightPasses: (x, y) ->
        @cells[x+','+y]?.lightPasses

    createFOV: ->
        new ROT.FOV.DiscreteShadowcasting(((x, y) => @_lightPasses(x, y)), {topology: LIGHT_TOPOLOGY})

    recalcFov: ->
        @fov = new ROT.FOV.PreciseShadowcasting(((x, y) => @_lightPasses(x, y)), {topology: LIGHT_TOPOLOGY})

    calcLightData: ->
        reflectivity = (x, y) => 
            @cells[x+','+y]?.reflectivity or 0

        lighting = new ROT.Lighting(reflectivity, {range: 12, passes: 2})
        lighting.setFOV(@fov)

        for key, entityList of @entities
            for entity in entityList
                lightInfo = entity.light
                if lightInfo
                    lighting.setLight(entity.getX(), entity.getY(), lightInfo.color)

        lightData = {}
        lighting.compute (x, y, color) ->
            lightData[x+','+y] = color

        return lightData

    calcVisible: ->
        @visible = {}
        @hasBeenVisible ?= {}
        @_visibleEntities = []
        for entity in @mirrorSeers
            @fov.compute(entity.getX(), entity.getY(), 12, (x, y, radius, visibility) =>
                key = x+','+y
                @visible[x+','+y] = visibility
                @hasBeenVisible[x+','+y] = true
                for e in @entities[key] or []
                    @_visibleEntities.push({entity: e, distance: radius})
            )

    
    visibleEntities: -> @_visibleEntities or []

    moveEntity: (entity, x, y) ->
        otherEntities = @entitiesAtCell(x, y)
        for a in otherEntities
            a.bump(entity)

        @removeEntity(entity, {removeActor: false})
        entity.setPosition(x, y)
        @addEntity(entity, x, y, {addActor: false})

        otherEntities = @entitiesAtCell(x, y)
        for b in otherEntities
            if b != entity
                b.afterBump(entity)

    removeEntity: (entity, opts) ->
        opts ?= {}

        x = entity.getX()
        y = entity.getY()
        entityList = @entities[KEY(x, y)]
        assert(entityList)
        found = undefined
        for e, i in entityList
            if e == entity
                found = entityList.splice(i, 1)
                assert(found[0] == e and e == entity)
                break

        assert (found)

        if opts.removeActor != false and entity.act
            @removeActor(entity)

            i = @mirrorSeers.indexOf(entity)
            if i != -1 then @mirrorSeers.splice(i, 1)

    addEntity: (entity, x, y, opts={}) ->
        key = KEY(x, y)
        entityList = @entities[key]
        if not entityList?
            entityList = @entities[key] = []

        entityList.push(entity)

        if opts.addActor != false and entity.act
            @addActor(entity)
            if entity.seesMirrors then @mirrorSeers.push(entity)

    wakeUpActors: ->
        for entity in @allEntities()
            if entity.act
                @addActor(entity)

    draw: ->
        @display.clear()
        @fog ?= {}
        lightData = @calcLightData()
        @calcVisible()

        add = ROT.Color.add
        multiply = ROT.Color.multiply
        baseColor = null

        for key, cell of @cells
            [x, y] = COORDS(key)

            baseColor = @fgs[key] or [255, 255, 255]

            light = lightData[key]

            fog = @fog[key] or 0
            if light
                intensity = light[0]
                if fog < intensity
                    fog = Math.min(70, intensity)
                    @fog[key] = fog

            if not light or (light and fog >= (light[0] or 0))
                light = [fog, fog, fog]

            if not light?
                light = @ambientLight

            dynamicLight = lightData[key]
            if dynamicLight? then light = clampColor(add(light, dynamicLight))

            finalColor = multiply(baseColor, light)
            lightColor = finalColor

            entityList = @entities[key]
            if not @visible[key]?
                entityList = (e for e in (entityList or []) when e.seeInFog)

            bg = null
            if entityList?.length
                topEntity = entityList[entityList.length-1]
                character = topEntity.char
                assert(character, "entity doesn't define .char")
                entityColor = topEntity.color
                if entityColor?
                    if typeof(entityColor) == 'string'
                        entityColor = ROT.Color.fromString(entityColor)

                    finalColor = multiply(finalColor, entityColor)
            else
                character = cell.char
                bg = @bgs[key] or null
                if bg then bg = ROT.Color.toRGB(multiply(bg, light))

            @display.draw(x, y, character, ROT.Color.toRGB(finalColor), bg or null)

        #
        # render mirrors
        #
        maxwidth = @display._options.width
        maxheight = @display._options.height

        if RENDER_MIRRORS
            for mirrorType, delta of mirrors
                cellList = @cellsByName[mirrorType] or []
                for key in cellList
                    # skip mirror if not lit
                    if not @visible[key] then continue

                    [mirrorx, mirrory] = COORDS(key)

                    xDelta = delta.dx
                    yDelta = delta.dy
                    rayXDelta = xDelta
                    rayYDelta = yDelta

                    # skip mirror if player isn't beyond its plane
                    planeBreak = false
                    for e in @mirrorSeers
                        if (xDelta and Math.sign(e.getX() - mirrorx) == xDelta) or
                           (yDelta and Math.sign(e.getY() - mirrory) == yDelta)
                            planeBreak = true
                            break
                    if planeBreak
                        continue

                    dx = 0
                    dy = 0
                    rayX = 0
                    rayY = 0
            
                    while true
                        dx += xDelta
                        dy += yDelta
                        rayX += rayXDelta
                        rayY += rayYDelta

                        [drawx, drawy] = [mirrorx + dx, mirrory + dy]
                        if drawx >= maxwidth or drawy >= maxheight or drawx < 0 or drawy < 0
                            break
                    
                        cellKey = (mirrorx - rayX) + ',' + (mirrory - rayY)
                        if not @cells[cellKey] then break

                        args = @display._data[cellKey]
                        if not args? then break

                        [x, y, ch, fg, bg] = args
                        cell = @cells[x+','+y]
                        @display.draw(drawx, drawy, ch, fg, bg)

                        if (rayXDelta < 0 and cell == cells.rightmirror) or 
                           (rayXDelta > 0 and cell == cells.leftmirror)
                            rayXDelta = -rayXDelta
                        if (rayYDelta < 0 and cell == cells.downmirror) or
                           (rayYDelta > 0 and cell == cells.upmirror)
                            rayYDelta = -rayYDelta

        undefined

window.Level = Level
