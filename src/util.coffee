if console != undefined and console.assert != undefined
    window.assert = (args...) ->
        return console.assert.apply(console, args)
else
    window.assert = (exp, message) ->
        if not exp
            throw message

class Point
    @distance: (pt1, pt2) ->
        dx = pt2[0] - pt1[0]
        dy = pt2[1] - pt1[1]
        Math.sqrt(dx*dx + dy*dy)

assert(Point.distance([0, 0], [1, 0]) == 1)
assert(Point.distance([0, 0], [3, 4]) == 5)

window.Point = Point

class Rect
    constructor: (@x1, @y1, @x2, @y2) ->

    @fromWH: (x, y, w, h) ->
        return new Rect(x, y, x+w, y+h)

    @fromRoom: (room) ->
        return new Rect(
            room.getLeft(),
            room.getTop(),
            room.getRight(),
            room.getBottom()
        )

    center: ->
        return [
            @x1 + (@x2 - @x1) / 2,
            @y1 + (@y2 - @y1) / 2
        ]

    containsXY: (x, y) ->
        return (
            x >= @x1 and
            x < @x2 and

            y >= @y1 and
            y < @y2)

window.Rect = Rect

window.isRGB = (o) ->
    return (o.length == 3 and 
            typeof o[0] == 'number' and
            typeof o[1] == 'number' and
            typeof o[2] == 'number')

window.clampColor = (c) ->
    (ROT.Color._clamp(c[i]) for i in [0..2])
