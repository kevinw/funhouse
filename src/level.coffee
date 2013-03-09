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
    constructor: ->
        @cells = {}
        @cellsByName = {}
        @entities = {}
        @generate()

        @ambientLight = [0, 0, 0]

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
        lighting = new ROT.Lighting(reflectivity, {range: 12, passes: 2})

        for key, entityList of @entities
            for entity in entityList
                lightInfo = entity.getLightInfo()
                if lightInfo
                    lighting.setLight(entity.getX(), entity.getY(), lightInfo.color)

        lightData = {}
        lighting.compute (x, y, color) ->
            lightData[KEY(x, y)] = color

        return lightData

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
                character = topEntity.char()
            else
                character = cell.char

            @display.draw(x, y, character, ROT.Color.toRGB(finalColor), null)

window.Level = Level
