fs     = require "fs"
path   = require "path"
util   = require "util"
pug    = require "pug"
errify = require "errify"

template = fs.readFileSync (path.join __dirname, "..", "templates", "error.pug"), "utf-8"
template = pug.compile template


class Fancy
  @stringify: (obj) ->
    stack = obj.stack
    return String stack if stack
    str = String obj
    if str is Object::toString.call obj then util.inspect obj else str

  @log: (logger) => (err) =>
    setImmediate logger, err, @stringify err

  @html: (err, cb) ->
    ideally = errify cb

    stack = @stringify err
    if err instanceof Error
      [_, line] = err.stack.split "\n"
      result = /at\s(.+\s)?\(?(.+)\:([0-9]+)\:([0-9]+)/.exec line

      if result
        name = result[2]
        row = +result[3]
        col = +result[4]

        await fs.readFile name, "utf-8", ideally defer file
        file    = file.split "\n"
        start   = if row - 6 < 0 then 0 else row - 6
        end     = row + 6
        excerpt = file[start..end]

    unless name
      err = new Error err
      row = col = start = 0
      excerpt = stack and (stack.split "\n") or []
      stack = err.stack

    cb null, template
      name:          err.name
      message:       err.message
      line:          row
      column:        col
      excerpt:       excerpt
      excerpt_start: start + 1
      stack:         stack

  @json: (err) ->
    error =
      message: err.message
      stack:   err.stack

    error[prop] = err[prop] for prop of err
    {error}


module.exports = Fancy
