LIGHT_TOPOLOGY = 8
RENDER_MIRRORS = true

KEY = (x, y) ->
    return x + ',' + y

window.COORDS = (key) ->
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
        @closedDoors = {}
        @bgs = {}
        @fgs = {}

        @depth = opts.depth

        @cellsByName = {}
        @entities = {}
        @mirrorSeers = []

        @generate(opts)
        @ambientLight = [0, 0, 0]
        @display = @game.display

    canMoveTo: (x, y, opts={}) ->
        key = KEY(x, y)
        cell = @cells[KEY(x, y)]
        if not cell?
            return {canMove: false}

        if opts.entities
            entities = (e for e in @entitiesAtCell(x, y) when not (e.blocksPathFinding is false))
            if (entities.length == 1 and entities[0] != opts.self) or entities.length > 1
                return {canMove: false}

        if cell.blocksMovement == false
            return {canMove: true}

        return {
            canMove: false
            bump: getBumpMessage(cell)
            bumpFunc: cell.bumpFunc
        }

    allEntities: ->
        all = []
        for key, entityList of @entities
            all = all.concat(entityList)
        all

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
            [x, y] = COORDS(key)

            if roomRect?
                if not roomRect.containsXY(x, y)
                    continue

            assert(@cells[key] == cells[type])
            if not @entities[key]?.length
                return [x, y]

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
        opts.numMonsters = Math.floor(@depth*2.5)
        opts.numFood = Math.floor(@depth*2.4)
        opts.numShells = Math.floor(@depth)
        mapInfo = @_generateDigger()
        @_placeEntities(mapInfo, opts)

        @recalcFov()

    _generateDigger: (opts) ->
        @width = Math.floor(50 + (@depth-1) * 2.9)
        @height = Math.floor(20 + (@depth-1) * 2.7)
        @roomDugPercentage = Math.min(1, .1 + @depth*.1)
        @roomRange = [[4, Math.floor(12+@depth/3.2)],
                      [3, Math.floor(10+@depth/3.2)]]

        mapOpts =
            roomWidth: @roomRange[0]
            roomHeight: @roomRange[1]
            timeLimit: Infinity

        if true
            constructor = ROT.Map.Uniform
            mapOpts.roomDugPercentage = @roomDugPercentage
        else
            constructor = ROT.Map.Digger
            mapOpts.dugPercentage = @roomDugPercentage

        digger = new constructor(@width, @height, mapOpts)
        digger.create (x, y, val) =>
            if val == 0
                @setCell(x, y, 'floor')
        rooms = digger.getRooms()

        roomInfos = []
        @roomInfos = roomInfos
        didMaze = false
        for room, n in rooms
            rect = Rect.fromRoom(room)
            roomInfo =
                room: room
                rect: rect
                area: rect.area()

            roomInfos.push(roomInfo)
            
            if roomInfo.area > 80 and not didMaze
                window.mazeRoom = roomInfo
                @_generateRoomMaze(roomInfo, opts)
                didMaze = true

        if true
            for n in [0..Math.floor(ROT.RNG.getUniform() * 4)]
                mirrorRoom = rooms.random()
                mirrorRoomRect = Rect.fromRoom(mirrorRoom)
                x1 = mirrorRoomRect.x1 - 1
                x2 = mirrorRoomRect.x2 + 1
                y1 = mirrorRoomRect.y1 - 1
                y2 = mirrorRoomRect.y2 + 1
                walls = [
                    =>
                        for x in [mirrorRoomRect.x1..mirrorRoomRect.x2]
                            if not @cells[x+','+y1]? and not @cells[x+','+(y1-1)]?
                                @setCell(x, y1, 'downmirror')

                    =>
                        for x in [mirrorRoomRect.x1..mirrorRoomRect.x2]
                            if not @cells[x+','+y2]? and not @cells[x+','+(y2+1)]?
                                @setCell(x, y2, 'upmirror')
                    =>
                        for y in [mirrorRoomRect.y1..mirrorRoomRect.y2]
                            if not @cells[x1+','+y]? and not @cells[(x1-1)+','+y]?
                                @setCell(x1, y, 'rightmirror')

                    =>
                        for y in [mirrorRoomRect.y1..mirrorRoomRect.y2]
                            if not @cells[x2+','+y]? and not @cells[(x2+1)+','+y]?
                                @setCell(x2, y, 'leftmirror')
                ]

                walls = walls.randomize()
                for n in [0..Math.floor(ROT.RNG.getUniform() * walls.length)]
                    walls[n]()


        # place walls
        if true
            for y in [0..@height]
                for x in [0..@width]
                    if not @cells[x+','+y]?
                        left = @cells[(x-1)+','+y]
                        right = @cells[(x+1)+'.'+y]
                        for [dx, dy] in ROT.DIRS['8']
                            if @cells[(x+dx)+','+(y+dy)] == cells.floor
                                @setCell(x, y, 'plywood')
                                break

        return digger

    _generateRoomMaze: (roomInfo, opts) ->
        rect = roomInfo.rect
        maze = new ROT.Map.IceyMaze(rect.width()+1, rect.height()+1, 0)
        maze.create (x, y, val) =>
            x = x + rect.x1
            y = y + rect.y1
            if val != 0 then @setCell(x, y, 'plywood')

        roomInfo.room.getDoors (x, y) =>
            for j in [y-1..y+1]
                for i in [x-1..x+1]
                    @setCell(i, j, 'floor')

    _generateMaze: (width, height) ->
        maze = new ROT.Map.EllerMaze(width, height)
        maze.create (x, y, val) =>
            if val == 0
                @setCell(x, y, 'floor')
            else
                @setCell(x, y, 'fourmirror')
        return {
            getRooms: -> [new ROT.Map.Feature.Room(0, 0, width, height)]
        }

    _generateRoom: (width, height) ->
        wallType = 'plywood'
        floorType = 'floor'

        for x in [0..width-1]
            @setCell(x, 0, wallType)
            @setCell(x, height-1, wallType)

        for y in [0..height-1]
            @setCell(0, y, wallType)
            @setCell(width-1, y, wallType)

        for y in [1..height-2]
            for x in [1..width-2]
                @setCell(x, y, floorType)

        return {
            getRooms: -> [new ROT.Map.Feature.Room(0, 0, width, height)]
        }


    _placeEntities: (mapInfo, opts) ->
        rooms = mapInfo.getRooms()

        # place down stairs
        exitRoom = rooms.random()
        exitRoomRect = Rect.fromRoom(exitRoom)
        [x, y] = @findFreeCell({room: exitRoom})
        @downStairs = new DownStairs(this, x, y)

        # place up stairs in a room kind of far away
        otherRooms = (r for r in rooms when r != exitRoom)
        if otherRooms.length
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

        if rooms.length > 1
            rooms = rooms.slice()
            roomsByDoorCount = {}
            for room in rooms
                doorCount = 0
                room.getDoors((x, y) -> doorCount += 1)
                roomsByDoorCount[doorCount] ?= []
                roomsByDoorCount[doorCount].push(room)

        if true
            iswall = (x, y) ->
                cell = @cells[KEY(x, y)]
                not cell or not (cell.blocksMovement is false)

            # doors
            for roomInfo in @roomInfos
                roomInfo.room.getDoors (x, y) =>
                    if (iswall(x-1,y) and iswall(x+1,y)) or
                       (iswall(x,y-1) and iswall(x,y+1))
                        return new Door(this, x, y)

            # place down monsters
            for i in [0..opts.numMonsters-1]
                [x, y] = @findFreeCell()
                if entranceRoom != exitRoom
                    failsafe = 0
                    while entranceRoomRect.containsXY(x, y)
                        assert((failsafe += 1) < 100)
                        [x, y] = @findFreeCell()
                new Monster(this, x, y)

            # place food
            for i in [0..opts.numFood-1]
                [x, y] = @findFreeCell()
                new Food(this, x, y)

            # place whelk shells
            for i in [0..opts.numShells-1]
                [x, y] = @findFreeCell()
                new WhelkShell(this, x, y)

    entryPosition: (delta) ->
        if delta > 0
            @upStairs?.position() or @upStairsPosition
        else
            @downStairs.position()

    _lightPasses: (x, y) ->
        key = x+','+y
        if @cells[key]?.lightPasses
            if not @closedDoors[key]
                return true

    createFOV: ->
        new ROT.FOV.DiscreteShadowcasting(((x, y) => @_lightPasses(x, y)), {topology: LIGHT_TOPOLOGY})

    recalcFov: ->
        @fov = new ROT.FOV.PreciseShadowcasting(((x, y) => @_lightPasses(x, y)), {topology: LIGHT_TOPOLOGY})

    calcLightData: ->
        reflectivity = (x, y) => 
            @cells[x+','+y]?.reflectivity or 0

        lighting = new ROT.Lighting(reflectivity, {range: constants.playerSightRadius, passes: constants.lightPasses})
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
            @fov.compute(entity.getX(), entity.getY(), constants.playerSightRadius, (x, y, radius, visibility) =>
                key = x+','+y
                @visible[x+','+y] = visibility
                @hasBeenVisible[x+','+y] = true
                for e in @entities[key] or []
                    @_visibleEntities.push({entity: e, distance: radius})
            )

        undefined
    
    visibleEntities: -> @_visibleEntities or []

    awardXp: (opts) ->
        for player in @mirrorSeers
            if player.awardXp
                player.awardXp(opts)

        undefined

    addEntity: (entity, x, y, opts={}) ->
        assert(entity.getX() == x)
        assert(entity.getY() == y)

        key = KEY(x, y)
        entityList = @entities[key]
        if not entityList?
            entityList = @entities[key] = []

        entityList.push(entity)

        if opts.addActor != false and entity.act
            @addActor(entity)
            if entity.seesMirrors then @mirrorSeers.push(entity)

        if not opts.skipBump
            for otherEntity in entityList.slice()
                if otherEntity != entity
                    entity.bump(otherEntity, opts)
                    otherEntity.bump(entity, opts)

            for b in entityList.slice()
                if b != entity
                    b.afterBump(entity, opts)
                    entity.afterBump(b, opts)

        undefined


    moveEntity: (entity, x, y) ->
        @removeEntity(entity, {removeActor: false})
        entity.setPosition(x, y)
        @addEntity(entity, x, y, {addActor: false})

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
                if entityList.length == 1 and entityList[0] instanceof Door
                    entityList[0].close()
                assert(found[0] == e and e == entity)
                break

        assert (found)

        if opts.removeActor != false and entity.act
            @removeActor(entity)

            i = @mirrorSeers.indexOf(entity)
            if i != -1 then @mirrorSeers.splice(i, 1)

    wakeUpActors: ->
        for entity in @allEntities()
            if entity.act
                @addActor(entity)

        undefined

    draw: ->
        @display.clear()
        @fog ?= {}
        lightData = @calcLightData()
        @calcVisible()

        add = ROT.Color.add
        multiply = ROT.Color.multiply
        baseColor = null

        camRect = @camera.getRect()
        for y in [camRect.y1..camRect.y2]
            for x in [camRect.x1..camRect.x2]
                screenX = x - camRect.x1
                screenY = y - camRect.y1
                key = x+','+y
                cell = @cells[key]
                if not cell? then continue
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
                opts = undefined
                if entityList?.length
                    topEntity = entityList[entityList.length-1]
                    character = topEntity.charFunc(x, y)
                    opts = if topEntity.drawOpts then topEntity.drawOpts() else undefined
                    if (entityColor = topEntity.color)?
                        if typeof(entityColor) == 'string'
                            entityColor = ROT.Color.fromString(entityColor)

                        finalColor = multiply(finalColor, entityColor)
                    if (entityBgColor = topEntity.bg)?
                        if typeof(entityBgColor) == 'string'
                            entityBgColor = ROT.Color.fromString(entityBgColor)
                        bg = entityBgColor
                else
                    character = cell.char
                    bg = @bgs[key] or null
                if bg then bg = ROT.Color.toRGB(multiply(bg, light))

                @display.draw(screenX, screenY, character, ROT.Color.toRGB(finalColor), bg or null, opts)

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

                        cellKey = (mirrorx - rayX) + ',' + (mirrory - rayY)
                        if not @cells[cellKey] then break

                        screenKey = @camera.getScreenKey(mirrorx - rayX, mirrory - rayY)
                        args = @display._data[screenKey]
                        if not args? then break

                        [drawx, drawy] = @camera.getScreenCoords(mirrorx + dx, mirrory + dy)
                        if drawx >= @camera.width or drawy >= @camera.height or drawx < 0 or drawy < 0
                            break
                    
                        args = args.slice()
                        args[0] = drawx
                        args[1] = drawy

                        cell = @cells[@camera.getWorldKey(x, y)]
                        @display.draw(args...)

                        if (rayXDelta < 0 and cell == cells.rightmirror) or 
                           (rayXDelta > 0 and cell == cells.leftmirror)
                            rayXDelta = -rayXDelta
                        if (rayYDelta < 0 and cell == cells.downmirror) or
                           (rayYDelta > 0 and cell == cells.upmirror)
                            rayYDelta = -rayYDelta

        undefined

    setCamera: (@camera) ->

window.Level = Level

class Camera
    constructor: (@entity, @width, @height) ->
        @getRect()

    getScreenCoords: (x, y) ->
        return [x-@rect.x1, y-@rect.y1]

    getScreenKey: (x, y) ->
        return (x-@rect.x1)+','+(y-@rect.y1)

    getWorldKey: (x, y) ->
        return (x+@rect.x1)+','+(y+@rect.y1)

    getRect: ->
        [x, y] = [@entity.getX() - Math.floor(@width/2), @entity.getY() - Math.floor(@height/2)]
        @rect = Rect.fromWH(x, y, @width, @height)

window.Camera = Camera
