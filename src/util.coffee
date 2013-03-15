if console != undefined and console.assert != undefined
    window.assert = console.assert.bind(console)#(args...) ->
        #return console.assert.apply(console, args)
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

window.queryString = (key) ->
    key = key.replace(/[*+?^$.\[\]{}()|\\\/]/g, "\\$&") # escape RegEx meta chars
    match = location.search.match(new RegExp("[?&]"+key+"=([^&]+)(&|$)"));
    return match and decodeURIComponent(match[1].replace(/\+/g, " "))

window.queryInt = (key) ->
    s = queryString(key)
    if s?
        n = parseInt(s, 10)
        if not isNaN(n)
            return n

window.htmlEntities = (str) ->
    String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;')

vector =
    cardinals:
        up: [0, -1]
        down: [0, 1]
        right: [1, 0]
        left: [-1, 0]

    add:      (a, b) -> [a[0] + b[0], a[1] + b[1]]
    subtract: (a, b) -> [a[0] - b[0], a[1] - b[1]]
    length:   (a) -> Math.sqrt(a[0]*a[0] + a[1]*a[1])
    length2:  (a) -> a[0]*a[0] + a[1]*a[1]

    projectOn: (self, v) ->
        s = (self[0] * v[0] + self[1] * v[1]) / (v[0] * v[0] + v[1] * v[1])
        [s * v[0], s * v[1]]

    closestCardinal:(a) ->
        maxDistance = 0
        for name, cardinalVector of vector.cardinals
            projected = vector.projectOn(a, cardinalVector)
            projectedLength = vector.length2(projected)
            if projectedLength > maxDistance
                longestVec = projected
                maxDistance = projectedLength

        vector.normalized(longestVec)

    normalized: (v) ->
        l = vector.length(v)
        [v[0]/l, v[1]/l]

window.vector = vector

window.extend = (obj, mixin) ->
    obj[name] = value for name, value of mixin
    obj

