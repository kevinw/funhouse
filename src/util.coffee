if console != undefined and console.assert != undefined
    window.assert = (args...) ->
        return console.assert.apply(console, args)
else
    window.assert = (exp, message) ->
        if not exp
            throw message

class Entity
    constructor: (@level, @_x, @_y) ->
        assert(@level)
        @level.addEntity(this, @_x, @_y)

    getSpeed: -> 100

    getX: -> @_x
    getY: -> @_y

    setPosition: (x, y) ->
        @_x = x
        @_y = y

window.Entity = Entity
