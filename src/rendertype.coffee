Errors = require "restify-errors"
errify = require "errify"
Fancy  = require "./fancy"


class RenderType
  @text: (path, obj) -> @send obj.toString()
  @html: (path, obj) -> @render path, obj
  @json: (path, obj) -> @json obj
  @yaml: (path, obj) -> @send (require "js-yaml").safeDump obj, skipInvalid: true
  @xml:  (path, obj) -> @send (require "xml") obj, indent: ' '
  @auto: (fallback = false, preference = ["yaml", "json", "html", "text"]) -> (req, res, next) =>
    res.rendr = =>
      type   = req.accepts preference
      type or= fallback
      next new Errors.NotAcceptableError unless type
      res.type type
      @[type].apply res, arguments
    next()


class RenderTypedErrors extends RenderType
  @Error404: (req, res, next) -> next new Errors.NotFoundError
  @log: ->
  @text: (err, req, res, next) -> super "", err.message
  @html: (err, req, res, next) -> super "error", err
  @json: (err, req, res, next) -> super "", err
  @yaml: (err, req, res, next) -> super "", err
  @xml:  (err, req, res, next) -> super "", err
  @auto: (fallback = false, preference = ["yaml", "json", "html", "text"], log = @log) -> (err, req, res, next) =>
    type   = req.accepts preference
    type or= fallback

    err.statusCode = err.status if err.status and not err.statusCode
    if err.statusCode < 400 or not err.statusCode then err.statusCode = 500

    if err.statusCode and not (err instanceof Error)
      {message}   = err
      err         = Errors.makeErrFromCode err.statusCode
      err.message = message if message

    log err
    return req.socket.destroy() if res._header

    res.status err.statusCode
    res.setHeader "X-Content-Type-Options", "nosniff"
    res.type type
    @[type].apply res, arguments


class FancyErrors extends RenderTypedErrors
  @text: (err, req, res, next) -> super message: Fancy.stringify err
  @html: (err, req, res, next) ->
    ideally = errify next
    await Fancy.html err, ideally defer html
    res.type "html"
    res.send html

  @json: (err, req, res, next) -> super Fancy.json err
  @yaml: (err, req, res, next) -> super Fancy.json err
  @xml:  (err, req, res, next) -> super Fancy.json err
  @auto: (fallback = false, preference = ["yaml", "json", "html", "text"], log = @log) ->
    super fallback, preference, Fancy.log log


RenderType.error       = Errors
RenderType.error.fromCode = Errors.makeErrFromCode
RenderType.Errors      = RenderTypedErrors
RenderType.FancyErrors = FancyErrors
module.exports         = RenderType
