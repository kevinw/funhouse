ambientLight = [0, 0, 0]

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

        @addStatus('You enter the funhouse.')
        @addStatus('The exit slams shut behind you.')
        @addStatus('Good luck!')

    addStatus: (msg) ->
        status = document.getElementById('status')

        div = document.createElement('div')
        div.appendChild(document.createTextNode(msg))

        status.appendChild(div)
        while status.childNodes.length > 3
            status.removeChild(status.childNodes[0])

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
