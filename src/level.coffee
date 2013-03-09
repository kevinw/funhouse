KEY = (x, y) ->
    assert(typeof(x) == 'number')
    assert(typeof(y) == 'number')
    return x + ',' + y

COORDS = (key) ->
    assert(typeof(key) == 'string')
    parts = key.split(",")
    assert(parts.length == 2)
    x = parseInt(parts[0])
    y = parseInt(parts[1])
    return [x, y]

class Level
    constructor: (@game) ->
        @cells = {}
        @cellsByName = {}
        @entities = {}
        @generate()

        @ambientLight = [0, 0, 0]

        @display = new ROT.Display {
            fontFamily: "Monaco" # TODO: load font
            fontSize: 22
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

    setCell: (x, y, type) ->
        cell = cells[type]
        assert (cell)
        key = KEY(x, y)

        @cells[key] = cell

        cellList = @cellsByName[type]
        if not cellList then cellList = @cellsByName[type] = []

        cellList.push(key)

    generate: ->
        digger = new ROT.Map.Digger()
        digger.create (x, y, val) =>
            if val == 0
                @setCell(x, y, 'floor')

        @recalcFov()

    recalcFov: ->
        lightPasses = (x, y) =>
            @cells[KEY(x, y)]?.lightPasses

        @fov = new ROT.FOV.PreciseShadowcasting(lightPasses, {topology: 4})

    calcLightData: ->
        reflectivity = (x, y) => 
            @cells[KEY(x, y)]?.reflectivity or 0

        lighting = new ROT.Lighting(reflectivity, {range: 12, passes: 2})
        lighting.setFOV(@fov)

        for key, entityList of @entities
            for entity in entityList
                lightInfo = entity.light
                if lightInfo
                    lighting.setLight(entity.getX(), entity.getY(), lightInfo.color)

        lightData = {}
        lighting.compute (x, y, color) ->
            lightData[KEY(x, y)] = color

        return lightData

    moveEntity: (entity, x, y) ->
        @removeEntity(entity, entity.getX(), entity.getY())
        entity.setPosition(x, y)
        @addEntity(entity, x, y)

    removeEntity: (entity, x, y) ->
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

        undefined

window.Level = Level
