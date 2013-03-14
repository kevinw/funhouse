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
            text = $("<div>").addClass('text').text(prop.label).appendTo(node)
            wasNew = true
        else
            bar = node.children('.bar')

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

window.updateLegendNodeForEntity = (node, entity) ->
    #while node.childNodes.length
        #node.removeChild(node.childNodes[0])

    header = $(node).children('.entity-header')
    if not header.length
        header = $("<div>").addClass('entity-header').appendTo(node)

    removeAllChildren(header[0])

    charSpan = document.createElement('span')
    if entity.color
        charSpan.setAttribute('style', 'color: %s;'.format(entity.color))
    charSpan.textContent = entity.char;
    header.append(charSpan)

    headerText = ": %s".format(entity.legendDesc or entity.constructor.name)
    header.append(document.createTextNode(headerText))

    node.appendChild(header[0])

    for prop in (entity.legendProps or [])
        propFunc = props[prop.type]
        [propNode, later] = propFunc(entity, prop, node)
        node.appendChild(propNode)
        if later then setTimeout(later, 0)

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




