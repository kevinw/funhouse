source_dir = 'src'

sources = [
    'js.coffee'
    'util.coffee'
    'config.coffee'
    'cells.coffee'
    'player.coffee'
    'level.coffee'
    'ui.coffee'
    'game.coffee'
    'gameinit.coffee'
]

fs = require 'fs'

{print} = require 'sys'
{spawn} = require 'child_process'

joined_file   = 'gen/funhouse.js'
minified_file = 'gen/funhouse-min.js'

build = (callback) ->
  coffee = spawn 'coffee', [
      '--map',
      '--join',
      'gen/funhouse.js',
      '--compile'
  ].concat((source_dir + '/' + s) for s in sources)

  coffee.stderr.on 'data', (data) ->
    process.stderr.write data.toString()
  coffee.stdout.on 'data', (data) ->
    print data.toString()
  coffee.on 'exit', (code) ->
    callback?() if code is 0

minify = (callback) ->
    cc = spawn 'closure-compiler', [
        '--js', joined_file
        '--js_output_file', minified_file
    ]

task 'build', 'Build all-in-one gen/funhouse.js src/ files', ->
  build()

task 'minify', 'Build and minify', ->
  build ->
      minify()
