MAP_DEBUG = false

fades = [
    66/255,
    128/255,
    255/255,
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
        $(div).html(msg)

        # remove older statuses
        @node.appendChild(div)
        while @node.childNodes.length > @limit
            @node.removeChild(@node.childNodes[0])

        visibleMessages = @messages.slice(-@limit)

        # fade status messages as they go into the past
        for node, i in @node.childNodes
            fade = if fades[i]? then fades[i] else fades[0]
            node.setAttribute('style', 'opacity: %s;'.format(fade))

class Game
    constructor: ({@seed}) ->
        @turn = 0

        @displaywidth = 50
        @displayheight = 25

        @statusMessages = new StatusMessages(document.getElementById('status'))

        if MAP_DEBUG
            mapDebug = $("#mapDebug")
            @debugDisplay = new ROT.Display({fontSize: 12})
            mapDebug.append(@debugDisplay.getContainer())

            @debugDisplayInfo = $("<pre>")
            mapDebug.append(@debugDisplayInfo)

        @display = new ROT.Display {
            fontFamily: "DejaVuSansMono, DejaVu Sans Mono, Monaco, Consolas, Inconsolata, monospace"
            fontSize: 21
            spacing: 1.1
            width: @displaywidth
            height: @displayheight
        }

        displayNode = @display.getContainer()
        document.getElementById('display').appendChild(displayNode)

        @engine = new ROT.Engine()
        @levelDepth = 0
        @levels = {}
        @switchLevel(1, {noUpStairs: true})

        @addStatus('You enter the funhouse.')
        @addStatus('The exit slams shut behind you.')
        @addStatus('Good luck!')

        @engine.start()

    url: ->
        window.location.origin + "/?seed=#{@seed}"

    switchLevel: (delta, opts) ->
        @levelDepth += delta
        @level = @levels[@levelDepth]

        @engine.clear()

        needWakeup = false
        if not @level?
            opts ?= {}
            opts.addActor = (actor) => @engine.addActor(actor)
            opts.removeActor = (actor) => @engine.removeActor(actor)
            opts.depth = @levelDepth

            @level = new Level(this, opts)
            @levels[@levelDepth] = @level
        else
            @level.wakeUpActors()

        if @debugDisplay?
            @debugDisplay.clear()
            @debugDisplay.setOptions(
                width: @level.width
                height: @level.height
            )

            for key, cell of @level.cells
                [x, y] = COORDS(key)
                if cell and cell.blocksMovement == false
                    @debugDisplay.DEBUG(x, y, 1)

            @debugDisplayInfo.text("""Level is #{@level.width}x#{@level.height} at depth #{@levelDepth} with #{@level.roomInfos.length} rooms
                                        dugPercentage: #{@level.roomDugPercentage}
                                        roomRange: #{@level.roomRange}""")

        [x, y] = @level.entryPosition(delta)

        if not @player?
            @player = new Player(@level, x, y)
            @camera = new Camera(@player, @displaywidth, @displayheight)
        else
            @player.moveToLevel(@level, x, y)

        @level.setCamera(@camera)

        @display.clear()


    addStatus: (msg) ->
        @statusMessages.addStatus(msg)

    updateLegend: (visibleEntities) ->
        legend = document.getElementById('legend')
        updateLegendNodes(legend, visibleEntities)

    lock: ->
        @level.draw()
        @updateLegend((e for e in @level.visibleEntities() when not e.entity.hideFromLegend))
        @engine.lock()

    unlock: ->
        @engine.unlock()

window.Game = Game
