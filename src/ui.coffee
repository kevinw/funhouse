# BEWARE OF SHITTY DOM CONSTRUCTION CODE

$ = Zepto

uiConstants =
    shakeEffectDuration: 400

legendLabel = (entity, prop) ->
    label = prop.label
    if typeof(label) == 'string' then label else label(entity)

props =
    bar: (entity, prop, parentNode) ->
        if (meterName = prop.meter)?
            meter = entity[meterName]
            name = meterName
            top = meter.value
            bottom = meter.max
        else
            name = prop.attr
            top = entity[prop.attr]
            assert(top?, "entity %s missing expected \"%s\"".format(entity, prop.attr))
            bottom = entity[prop.maxAttr]
            assert(bottom?, "entity %s missing expected \"%s\"".format(entity, prop.maxAttr))

        percentage =  Math.min(1, top / bottom) * 100

        classname = 'prop-' + name
        node = $(parentNode).children('.' + classname)
        wasNew = false
        if not node.length
            node = $("<div>").addClass('progress').addClass(classname)
            bar = $("<div>").addClass('bar').appendTo(node)
            text = $("<div>").addClass('text').appendTo(node)
            wasNew = true
        else
            bar = node.children('.bar')
            text = node.children('.text')

        text.text(legendLabel(entity, prop))

        if prop.color?
            bar.css('background', prop.color)

        later = -> # called after setTimeout so CSS animation takes effect
            bar.css('width', percentage + '%')

        if wasNew
            later()
            later = undefined

        return [node[0], later]

removeAllChildren = (node) ->
    while node.childNodes.length
        node.removeChild(node.childNodes[0])

updateEntityStatus = (node, entity) ->
    node = $(node)

    if not state = entity.state
        return node.children('.entity-state').remove()

    if (stateNode = node.children('.entity-state')).length == 0
        stateNode = $("<div>").addClass('entity-state')

    stateNode.appendTo(node)

    stateNode.text('(%s)'.format(state))

entitySpan = (entity) ->
    charSpan = document.createElement('span')
    if entity.color
        charSpan.setAttribute('style', 'color: %s;'.format(entity.color))
    charSpan.textContent = entity.char;
    charSpan

window.updateLegendNodeForEntity = (node, entity) ->
    header = $(node).children('.entity-header')
    if not header.length
        header = $("<div>").addClass('entity-header').appendTo(node)

    removeAllChildren(header[0])
    header.append(entitySpan(entity))

    headerText = ": %s".format(entity.legendDesc or entity.constructor.name)
    header.append(document.createTextNode(headerText))

    node.appendChild(header[0])

    if entity.effect?.damage
        entity.effect.damage = 0 # TODO: use an actual publish subscribe thing, this is hacky
        $(node).addClass('shake')
        remove = -> $(node).removeClass('shake')
        setTimeout(remove, uiConstants.shakeEffectDuration)

    for prop in (entity.legendProps or [])
        propFunc = props[prop.type]
        [propNode, later] = propFunc(entity, prop, node)
        node.appendChild(propNode)
        if later then setTimeout(later, 0)

    updateEntityStatus(node, entity)

window.updateLegendNodes = (legendNode, entitiesToShow) ->
    allNodes = $(legendNode).children('div')

    seen = {}
    for {entity} in entitiesToShow
        id = 'entity-' + entity.guid
        node = document.getElementById(id) or $('<div>')
            .attr('id', id)
            .addClass('legend-entry')[0]
        legendNode.appendChild(node)
        updateLegendNodeForEntity(node, entity)
        seen[id] = true

    # remove old
    toDelete = (n for n in legendNode.children when not seen[n.getAttribute('id')])
    legendNode.removeChild(n) for n in toDelete

sortedBucketed = (items) ->
    byClass = {}
    bucketed = []
    for item in items
        if not byClass[item.constructor.name]?
            bucketed.push(byClass[item.constructor.name] = [])

        classItems = byClass[item.constructor.name]
        classItems.push(item)

    bucketed

window.showInventory = (inventory, after) ->
    invnode = $("<div>")
        .attr('id', 'inventory')
        .addClass('dialog')

    letterCode = 'A'.charCodeAt(0)
    bucketedItems = sortedBucketed(inventory.items)
    itemsByLetter = {}
    for itemInfo in bucketedItems
        letter = String.fromCharCode(letterCode).toLowerCase()
        itemsByLetter[letterCode] = itemInfo
        $("<div>")
            .addClass("inv-item")
            .text('%s) '.format(letter))
            .append(inventoryText(itemInfo))
            .appendTo(invnode)

        letterCode += 1

    if not bucketedItems.length
        $("<span>").text('(Your pockets are empty.)').appendTo(invnode)

    $(invnode).append(
        $("<div>")
            .addClass('inv-escape')
            .text('ESC) close inventory'))

    $("#game").append(invnode)

    onKey = (e) ->
        keyCode = e.keyCode
        return if e.altKey

        if keyCode == ROT.VK_ESCAPE or keyCode == ROT.VK_I
            dismiss()
        else if item = itemsByLetter[keyCode]
            window.removeEventListener('keydown', onKey)
            showItemDetail(item, inventory, (closeInventory) ->
                window.addEventListener('keydown', onKey)
                if closeInventory then dismiss(true))
        else
            return

        e.preventDefault()

    dismiss = (takeTurn) ->
        window.removeEventListener('keydown', onKey)
        invnode.remove()
        after(takeTurn)

    window.addEventListener('keydown', onKey)

showItemDetail = (itemInfo, inventory, after) ->
    oneItem = itemInfo[0]

    detailnode = $("<div>")
        .attr('id', 'item-detail')
        .addClass('dialog')

    header = itemDescWithQuantity(itemInfo)
        .addClass('item-detail-header')
        .appendTo(detailnode)

    if oneItem.inventoryDesc
        $("<div>")
            .addClass('item-detail-desc')
            .html(oneItem.inventoryDesc())
            .appendTo(detailnode)

    actions = $("<div>")
        .addClass('item-actions')
        .appendTo(detailnode)

    actionKeycodes = {}

    for useFunc in oneItem.useFuncs()
        do (useFunc) ->
            label = useFunc.label
            shortcutKeyIndex = 0

            shortcutKey = label[shortcutKeyIndex]
            keycode = shortcutKey.toUpperCase().charCodeAt(0)
            actionKeycodes[keycode] = ->
                useFunc.call(oneItem, inventory)

            button = $('<div>')
                .addClass('item-action')
                .appendTo(actions)
                .append(document.createTextNode(label.substr(0, shortcutKeyIndex)))
                .append($("<span>").addClass('shortcut-key').text(shortcutKey))
                .append(document.createTextNode(label.substr(shortcutKeyIndex+1)))
        
    $("#game").append(detailnode)

    onKey = (e) ->
        return if e.altKey
        keyCode = e.keyCode
        if keyCode == ROT.VK_ESCAPE
            dismiss()
        else if (cb = actionKeycodes[keyCode])
            cb()
            dismiss(true)
        else
            return

        e.preventDefault()

    dismiss = (closeInventory) ->
        window.removeEventListener('keydown', onKey)
        detailnode.remove()
        after(closeInventory)

    window.addEventListener('keydown', onKey)

itemDescWithQuantity = (itemInfo) ->
    oneItem = itemInfo[0]
    quantity = itemInfo.length
    span = $("<span>").text(oneItem.statusDesc())
    if quantity > 1
        span.append(document.createTextNode(' '))
        span.append($("<span>")
                        .addClass('inv-quantity')
                        .text('<%s>'.format(quantity)))
    span


inventoryText = (itemInfo) ->
    oneItem = itemInfo[0]

    span = $("<span>")
    span.append(entitySpan(oneItem))
    span.append(document.createTextNode(' '))
    span.append(itemDescWithQuantity(itemInfo))
    span
