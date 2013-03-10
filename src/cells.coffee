cells =
    floor:
        char: '·'
        reflectivity: 0.3
        lightPasses: true
        blocksMovement: false

    plywood:
        char: '#'

    leftmirror:
        char: '|'
    upmirror:
        char: '-'

for cellName, cell of cells
    cell.name = cellName

window.cells = cells
