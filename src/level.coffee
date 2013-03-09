KEY = (x, y) ->
    assert(typeof(x) == 'number')
    assert(typeof(y) == 'number')
    return x + ',' + y

class Level
    constructor: ->
        @cells = {}
        @cellsByName = {}

        @entities = {}

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


window.Level = Level
