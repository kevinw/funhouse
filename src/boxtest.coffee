display = ROT.Display
    fontFamily: "DejaVuSansMono, DejaVu Sans Mono, Monaco, Consolas, Inconsolata, monospace"
    fontSize: 21
    spacing: 1.1
    width: @displaywidth
    height: @displayheight


class Map
    construct: ->
        resize
        @lightPasses = new ArrayBuffer(16)
    
document.body.appendChild(display.getContainer())
