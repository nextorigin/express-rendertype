util     = require "util"
{expect} = require "chai"
{spy}    = require "sinon"
spy.on   = spy
extend   = util._extend


RenderType = require "../src/rendertype"


types = [
  "text"
  "html"
  "json"
  "yaml"
  "xml"
]

describe "RenderType", ->
  it "has class methods for all supported types", ->
    for type in types
      expect(RenderType[type]).to.be.a "function"

  describe "#auto", ->
    rendr = null

    beforeEach ->
      rendr = RenderType.auto()

    afterEach ->
      rendr = null

    it "returns a function", ->
      expect(rendr).to.be.a "function"

    describe "returned function", ->
      it "sets a rendr function on the res object", ->
        res = {}
        rendr null, res, ->
        expect(res.rendr).to.be.a "function"

      describe "res.rendr", ->
        it "automatically chooses the render type", (done) ->
          blackhat = spy()
          whitehat = spy()
          type     = "html"
          path     = "/pricing"
          obj      = a: 1
          req      = accepts: -> type
          res      = type: blackhat, status: (->), setHeader: (->), render: whitehat
          rendr req, res, ->
          res.rendr path, obj

          expect(blackhat.called).to.be.true
          expect(blackhat.calledWith type).to.be.true
          expect(whitehat.called).to.be.true
          expect(whitehat.calledWith path, obj).to.be.true
          done()

describe "RenderTypedErrors", ->
  RenderTypedErrors = RenderType.Errors

  it "has class methods for all supported types", ->
    for type in types
      expect(RenderTypedErrors[type]).to.be.a "function"

  describe "#auto", ->
    rendr = null

    beforeEach ->
      rendr = RenderTypedErrors.auto()

    afterEach ->
      rendr = null

    it "returns a function", ->
      expect(rendr).to.be.a "function"

    describe "returned function", ->
      it "automatically chooses the render type", (done) ->
        blackhat = spy()
        whitehat = spy()
        type     = "text"
        req      = accepts: -> type
        res      = type: blackhat, status: (->), setHeader: whitehat, send: (->)
        rendr (new Error "fail"), req, res, done

        expect(blackhat.called).to.be.true
        expect(blackhat.calledWith type).to.be.true
        expect(whitehat.called).to.be.true
        expect(whitehat.calledWith "X-Content-Type-Options", "nosniff").to.be.true
        done()

      it "creates an error from a status code without a message", (done) ->
        blackhat = spy()
        whitehat = spy()
        status   = 422
        type     = "json"
        req      = accepts: -> type
        res      = type: (->), status: blackhat, setHeader: (->), json: whitehat
        rendr {status}, req, res, done

        expect(blackhat.called).to.be.true
        expect(blackhat.calledWith status).to.be.true
        expect(whitehat.called).to.be.true
        expect(whitehat.args[0][0]).to.be.an.instanceof Error
        expect(whitehat.args[0][0].statusCode).to.equal status
        done()

      it "creates an error from a status code and a message", (done) ->
        blackhat = spy()
        whitehat = spy()
        status   = 422
        message  = "fail"
        type     = "json"
        req      = accepts: -> type
        res      = type: (->), status: blackhat, setHeader: (->), json: whitehat
        rendr {status, message}, req, res, done

        expect(blackhat.called).to.be.true
        expect(blackhat.calledWith status).to.be.true
        expect(whitehat.called).to.be.true
        expect(whitehat.args[0][0]).to.be.an.instanceof Error
        expect(whitehat.args[0][0].statusCode).to.equal status
        expect(whitehat.args[0][0].message).to.equal message
        done()


describe "FancyErrors", ->
  FancyErrors = RenderType.FancyErrors

  it "has class methods for all supported types", ->
    for type in types
      expect(FancyErrors[type]).to.be.a "function"

  describe "#auto", ->
    rendr = null

    beforeEach ->
      rendr = FancyErrors.auto()

    afterEach ->
      rendr = null

    it "returns a function", ->
      expect(rendr).to.be.a "function"

    describe "returned function", ->
      it "automatically chooses the render type", (done) ->
        blackhat = spy()
        whitehat = spy()
        type     = "html"
        req      = accepts: -> type
        await
          res      = type: blackhat, status: (->), setHeader: (->), send: defer payload
          rendr (new Error "fail"), req, res, done

        expect(blackhat.called).to.be.true
        expect(blackhat.calledWith type).to.be.true
        expect(payload).to.match /fail/
        expect(payload).to.match /new Error "fail"/
        done()

      it "jsonifies errors", (done) ->
        blackhat = spy()
        whitehat = spy()
        message  = "fail"
        type     = "json"
        req      = accepts: -> type
        await
          res      = type: blackhat, status: (->), setHeader: (->), json: defer payload
          rendr (new Error "fail"), req, res, done

        expect(blackhat.called).to.be.true
        expect(blackhat.calledWith type).to.be.true
        expect(payload).to.not.be.instanceof Error
        expect(payload.error.message).to.match /fail/
        expect(payload.error.stack).to.exist
        done()

      it "yamlifies errors", (done) ->
        blackhat = spy()
        whitehat = spy()
        message  = "fail"
        type     = "yaml"
        req      = accepts: -> type
        await
          res      = type: blackhat, status: (->), setHeader: (->), send: defer payload
          rendr (new Error "fail"), req, res, done

        expect(blackhat.called).to.be.true
        expect(blackhat.calledWith type).to.be.true
        expect(payload).to.not.be.instanceof Error
        expect(payload).to.match /fail/
        expect(payload).to.match /stack:/
        done()

