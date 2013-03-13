props =
    bar: (entity, prop) ->
        if (meterName = prop.meter)?
            meter = entity[meterName]
            top = meter.value
            bottom = meter.max
        else
            top = entity[prop.attr]
            assert(top?, "entity %s missing expected \"%s\"".format(entity, prop.attr))
            bottom = entity[prop.maxAttr]
            assert(bottom?, "entity %s missing expected \"%s\"".format(entity, prop.maxAttr))

        percentage =  Math.min(1, top / bottom) * 100

        node = $("<div>").addClass('progress')
        bar = $("<div>").addClass('bar')
        bar.css('width', percentage + '%')
        if prop.color?
            bar.css('background', prop.color)
        node.append(bar)

        text = $("<div>").addClass('text').text(prop.label)
        node.append(text)

        return node[0]

window.updateLegendNodeForEntity = (node, entity) ->
    while node.childNodes.length
        node.removeChild(node.childNodes[0])

    header = document.createElement('div')

    charSpan = document.createElement('span')
    if entity.color
        charSpan.setAttribute('style', 'color: %s;'.format(entity.color))
    charSpan.textContent = entity.char;
    header.appendChild(charSpan)

    headerText = ": %s".format(entity.legendDesc or entity.constructor.name)
    header.appendChild(document.createTextNode(headerText))

    node.appendChild(header)

    for prop in (entity.legendProps or [])
        propFunc = props[prop.type]
        node.appendChild(propFunc(entity, prop))

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




