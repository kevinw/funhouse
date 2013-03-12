fades = [
    [66, 66, 66],
    [128, 128, 128],
    [255, 255, 255],
]

class StatusMessages
    limit: 3

    constructor: (@node) ->
        @messages = []

    addStatus: (msg) ->
        @messages.push
            text: msg
            color: [255, 255, 255]

        div = document.createElement('div')
        div.appendChild(document.createTextNode(msg))

        # remove older statuses
        @node.appendChild(div)
        while @node.childNodes.length > @limit
            @node.removeChild(@node.childNodes[0])

        visibleMessages = @messages.slice(-@limit)

        # fade status messages as they go into the past
        for node, i in @node.childNodes
            color = ROT.Color.multiply(visibleMessages[i].color, fades[i])
            node.setAttribute('style', 'color: %s;'.format(ROT.Color.toRGB(color)))

class Game
    display: null
    map: {}
    engine: null
    player: null
    pedro: null
    ananas: null
    actors: []

    constructor: ->
        @display = new ROT.Display {
            fontFamily: "Monaco" # TODO: load font
            fontSize: 18
            spacing: 1.1
        }

        displayNode = @display.getContainer()
        document.getElementById('display').appendChild(displayNode)

        @engine = new ROT.Engine()
        @levelDepth = 0
        @levels = {}
        @switchLevel(1, {noUpStairs: true})
        @engine.start()

        @statusMessages = new StatusMessages(document.getElementById('status'))

        @addStatus('You enter the funhouse.')
        @addStatus('The exit slams shut behind you.')
        @addStatus('Good luck!')

    switchLevel: (delta, opts) ->
        @levelDepth += delta
        @level = @levels[@levelDepth]

        @engine.clear()

        needWakeup = false
        if not @level?
            opts ?= {}
            opts.addActor = (actor) => @engine.addActor(actor)
            opts.removeActor = (actor) => @engine.removeActor(actor)

            @level = new Level(this, opts)
            @levels[@levelDepth] = @level
        else
            @level.wakeUpActors()

        [x, y] = @level.entryPosition(delta)

        if not @player?
            @player = new Player(@level, x, y)
        else
            @player.moveToLevel(@level, x, y)

        @display.clear()

    addStatus: (msg) ->
        @statusMessages.addStatus(msg)

    updateLegend: ->
        legend = document.getElementById('legend')
        while legend.childNodes.length
            legend.removeChild(legend.childNodes[0])
        legend.appendChild(document.createTextNode('@: You'))

    lock: ->
        @level.draw()
        @updateLegend()
        @engine.lock()

    unlock: ->
        @engine.unlock()

window.Game = Game
