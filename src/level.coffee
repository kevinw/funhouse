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
    canMoveTo: (x, y) ->
        key = KEY(x, y)
        cell = @cells[KEY(x, y)]
        if not cell?
            return false

        if cell.blocksMovement == false
            return true

        return false

    constructor: (@game) ->
        @cells = {}
        @cellsByName = {}
        @entities = {}
        @generate()

        @ambientLight = [0, 0, 0]

        @display = new ROT.Display {
            fontFamily: "Monaco" # TODO: load font
            fontSize: 18
            spacing: 1.1
        }

    findFreeCell: (type='floor') ->
        cellList = @cellsByName[type]
        assert(cellList.length)
        while true
            # TODO: bust out of this loop
            key = cellList.random()
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
            cellList = @cellsByName[oldCell.name]
            i = cellList.indexOf(key)
            if i != -1 then cellList.splice(i, 1)

        if @cells[key]? then


        @cells[key] = cell

        cellList = @cellsByName[type]
        if not cellList then cellList = @cellsByName[type] = []

        cellList.push(key)

    generate: ->
        if false
            digger = new ROT.Map.Digger()
            digger.create (x, y, val) =>
                if val == 0
                    @setCell(x, y, 'floor')
        else
            for y in [3..10]
                for x in [3..15]
                    @setCell(x, y, 'floor')

            for y in [3..10]
                @setCell(16, y, 'leftmirror')

            for x in [3..15]
                @setCell(x, 11, 'upmirror')

        @recalcFov()

        for i in [0..9]
            [x, y] = @findFreeCell()
            new Food(this, x, y)

    recalcFov: ->
        lightPasses = (x, y) =>
            @cells[x+','+y]?.lightPasses

        @fov = new ROT.FOV.PreciseShadowcasting(lightPasses, {topology: 4})

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

    moveEntity: (entity, x, y) ->
        @removeEntity(entity)
        entity.setPosition(x, y)

        for otherEntity in (@entities[KEY(x, y)] or [])
            otherEntity.bump(entity)

        @addEntity(entity, x, y)

    removeEntity: (entity) ->
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

    addEntity: (entity, x, y) ->
        key = KEY(x, y)
        entityList = @entities[key]
        if not entityList?
            entityList = @entities[key] = []

        entityList.push(entity)

    draw: ->
        lightData = @calcLightData()

        for key, cell of @cells
            [x, y] = COORDS(key)

            baseColor = if @cells[key] then [100, 100, 100] else [50, 50, 50]
            light = @ambientLight

            dynamicLight = lightData[key]
            if dynamicLight?
                light = ROT.Color.add(light, dynamicLight)

            finalColor = ROT.Color.multiply(baseColor, light)

            entityList = @entities[key]
            if entityList?.length
                topEntity = entityList[entityList.length-1]
                character = topEntity.char
                assert(character, "entity doesn't define .char")
                entityColor = topEntity.color
                if entityColor?
                    if typeof(entityColor) == 'string'
                        entityColor = ROT.Color.fromString(entityColor)

                    finalColor = ROT.Color.multiply(finalColor, entityColor)
            else
                character = cell.char

            @display.draw(x, y, character, ROT.Color.toRGB(finalColor), null)

        # render mirrors

        for mirrorType, {dx, dy} in mirrors
            for key in @cellsByName[mirrorType]
                [mirrorx, mirrory] = COORDS(key)

                dx = 0
                dy = 0
        
                while true
                    dx += xDelta
                    dy += yDelta
                
                    args = @display._data[(mirrorx - dx)+','+(mirrory - dy)]
                    if not args?
                        break

                    [x, y, ch, fg, bg] = args
                    @display.draw(mirrorx + dx, mirrory + dy, ch, fg, bg)

        undefined

window.Level = Level
