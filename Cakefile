source_dir = 'src'

fs = require 'fs'
{print} = require 'util'
{spawn} = require 'child_process'
{createHash} = require('crypto')

hashFile = (filename) ->
    createHash('sha512').update(fs.readFileSync(filename)).digest('hex')

sources = [
    'js.coffee'
    'util.coffee'
    'boxdrawing.coffee'
    'config.coffee'
    'cells.coffee'
    'player.coffee'
    'level.coffee'
    'ui.coffee'
    'game.coffee'
    'gameinit.coffee'
]

joined_file   = 'gen/funhouse.js'
minified_file = 'gen/funhouse-min.js'

spawn_check = (callback, cmd, args) ->
    proc = spawn cmd, args
    proc.stderr.on 'data', (data) ->
        process.stderr.write data.toString()
    proc.stdout.on 'data', (data) ->
        print data.toString()
    proc.on 'exit', (code) ->
        callback?() if code is 0

build = (callback) ->
  command_line = 'cat '
  for s in sources
    command_line = command_line + " " + source_dir + "/" + s
  command_line = command_line + " | coffee --compile --stdio > gen/funhouse.js"
  spawn_check callback, 'bash', ['-c', command_line]

minify = (callback) ->
    spawn_check callback, 'closure-compiler', [
        '--js', joined_file
        '--js_output_file', minified_file
    ]

task 'build', "Build all-in-one #{joined_file} from sources", ->
  build()

task 'minify', "Build minified all-on-one #{minified_file}", ->
  build ->
      minify()

build_release = (callback) ->
    build ->
        minify()

watch = (callback) ->
    spawn_check callback, 'coffee', [
        '--lint'
        '--map'
        '--compile'
        '--watch'
        source_dir
    ]

task 'foo', 'try hashing a file', ->
  print(hashFile('Cakefile') + "\n")

task 'watch', 'watch src/ directory for coffee-script changes, and compile them to js', ->
    watch()
