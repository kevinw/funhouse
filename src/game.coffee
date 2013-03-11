ambientLight = [0, 0, 0]

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
        @level = new Level(this)

        displayNode = @level.display.getContainer()
        document.getElementById('display').appendChild(displayNode)

        [x, y] = @level.findFreeCell('floor')
        @player = new Player(@level, x, y)

        @engine = new ROT.Engine()
        @engine.addActor(@player)
        @engine.start()

        @statusMessages = new StatusMessages(document.getElementById('status'))

        @addStatus('You enter the funhouse.')
        @addStatus('The exit slams shut behind you.')
        @addStatus('Good luck!')

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
