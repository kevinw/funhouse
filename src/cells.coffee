mirrorBumps = "
You can't see yourself go on forever, because no matter how you stand, your head gets in the way.
"

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
    leftmirror:
        reflectivity: 0.1
        char: '|'
        bump: mirrorBumps
    upmirror:
        reflectivity: 0.1
        char: '-'
        bump: mirrorBumps
    downmirror:
        reflectivity: 0.1
        char: '-'
        bump: mirrorBumps

colorArrayFromStrings = (a) -> (ROT.Color.fromString(c) for c in a)

for cellName, cell of cells
    cell.name = cellName
    if cell.bg?
        cell.bg = colorArrayFromStrings(cell.bg)
    if cell.fg?
        if typeof(cell.fg) == 'string'
            cell.fg = [cell.fg]
        cell.fg = colorArrayFromStrings(cell.fg)

console.log(cells)

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
