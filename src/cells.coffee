mirrorBumps = "
You glance at yourself in the mirror.
"

mirrorBumpFunc = (entity) ->
    dmgAmount = 5
    entity.damage
        sentence: 'You glance at yourself in the mirror. %s'.format(
            statusColor(constants.selfEsteemColor, '(%s self-esteem)'.format(
                statusColor('red', '' + (-dmgAmount))
            ))
        )
        amount: 5
    return false

cells =
    floor:
        char: '·'
        reflectivity: 0.3
        lightPasses: true
        blocksMovement: false

    plywood:
        reflectivity: 0.1
        char: '#'
        bg: ['#965922', '#a66a22', '#8b4a14', '#af6e2a']
        fg: '#2d0a04'
        bump: 'The plywood is firm and unyielding.'

    rightmirror:
        reflectivity: 0.1
        char: '|'
        bump: mirrorBumps
        bumpFunc: mirrorBumpFunc
    leftmirror:
        reflectivity: 0.1
        char: '|'
        bump: mirrorBumps
        bumpFunc: mirrorBumpFunc
    upmirror:
        reflectivity: 0.1
        char: '-'
        bump: mirrorBumps
        bumpFunc: mirrorBumpFunc
    downmirror:
        reflectivity: 0.1
        char: '-'
        bump: mirrorBumps
        bumpFunc: mirrorBumpFunc
    fourmirror:
        reflectivity: 0.1
        char: '©'
        bumpFunc: mirrorBumpFunc
        

colorArrayFromStrings = (a) -> (ROT.Color.fromString(c) for c in a)

for cellName, cell of cells
    cell.name = cellName
    if cell.bg?
        cell.bg = colorArrayFromStrings(cell.bg)
    if cell.fg?
        if typeof(cell.fg) == 'string'
            cell.fg = [cell.fg]
        cell.fg = colorArrayFromStrings(cell.fg)

getBumpMessage = (cell) ->
    bumps = cell.bump
    return if not bumps?

    if typeof bumps == 'string'
        msgs = (msg.trim() for msg in bumps.split('\n'))
        msgs = (msg for msg in msgs if msg.length > 0)
        cell.bump = msgs
        bumps = cell.bump

    assert(typeof bumps == 'object' and bumps.length)

    return bumps.random()

window.cells = cells
window.getBumpMessage = getBumpMessage
