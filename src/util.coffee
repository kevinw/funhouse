if console != undefined and console.assert != undefined
    window.assert = (args...) ->
        return console.assert.apply(console, args)
else
    window.assert = (exp, message) ->
        if not exp
            throw message

class Entity
    constructor: (@game, @_x, @_y) ->

    getSpeed: -> 100

    getX: -> @_x
    getY: -> @_y

window.Entity = Entity
