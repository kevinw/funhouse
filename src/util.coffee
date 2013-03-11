if console != undefined and console.assert != undefined
    window.assert = (args...) ->
        return console.assert.apply(console, args)
else
    window.assert = (exp, message) ->
        if not exp
            throw message
