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

    rightmirror:
        char: '|'
        bump: mirrorBumps
    leftmirror:
        char: '|'
        bump: mirrorBumps
    upmirror:
        char: '-'
        bump: mirrorBumps
    downmirror:
        char: '-'
        bump: mirrorBumps

for cellName, cell of cells
    cell.name = cellName

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
