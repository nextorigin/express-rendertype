# express-rendertype
Express middleware to (automatically) render content and errors to content-type

This is basically a mashup of

  * **[express-errs][1]** (Rails-inspired error handler for Express applications), and
  * **[errorhandler][2]** (full stack traces and util.inspect of objects),
  * a nod to **[express-error-responses][3]**,
  * with a helper for **[restify/errors][4]** Error Classes thrown in.

---

  * [Installation](#installation)
  * [Usage](#usage)
    - [Rendering content](#rendering-content)
      + [render.auto(fallback, preference)](#renderautofallback--false-preference--yaml-json-html-text)
      + [res.rendr(path, obj)](#resrendrpath---obj)
    - [Rendering errors](#rendering-errors)
      + [Status code](#status-code)
      + [Error library](#error-library)
      + [Objects](#objects)
    - [(Fancy) Error-handling middleware](#fancy-error-handling-middleware)
      + [render.FancyErrors.auto(fallback, preference, log)](#renderfancyerrorsautofallback-preference-log)
      + [render.Errors.auto(fallback, preference, log)](#rendererrorsautofallback-preference-log)

## Installation

    npm install --save express-rendertype

## Usage

```coffee
render = require "express-rendertype"

app = express()
```

### Rendering content

#### render.auto(fallback = false, preference = ["yaml", "json", "html", "text"])
create a .rendr method on the res object, falling back to json as default
```coffee
app.use render.auto "json"
```

#### res.rendr(path = "", obj)
render to json or whichever content-type the client accepts
```coffee
app.get "/someroute", (req, res, next) -> res.rendr "path/to/template", obj
```

### Rendering errors

#### Status code
pass an error from just a status code
```coffee
app.post "/noauthroute", (req, res, next) -> next status: 401
```

#### Error library
create an error with stacktrace in context from a status code
```coffee
app.put "/payme", (req, res, next) -> next render.error.fromCode 402
```

throw an error with message from the error library
```coffee
app.get "/gatekeeper", (req, res, next) ->
  throw new render.error.LockedError "I am the keymaster"
```
*See also: [**restify/errors**](https://github.com/restify/errors)*

#### Objects
pass an object as the error
```coffee
app.delete "/session", (req, res, next) -> next {foo: "bar", baz: "booze"}
```

### (Fancy) Error-handling middleware
add the error-handling middleware **after all routes**
```coffee
app.get ...
app.post ...
app.put ...
...
app.use render.FancyErrors.auto "text" if (@app.get "env") is "development"
app.use render.Errors.auto()
```

#### render.FancyErrors.auto(fallback, preference, log)
#### render.Errors.auto(fallback, preference, log)
Errors and FancyErrors are the same, except FancyErrors will log the stack to all content-types.  FancyErrors even has a nice code excerpt when rendered to HTML.
```coffee
app.use render.Errors.auto "html", ["html", "json"], console.log
```

MIT Licensed. (C) 2016 doublerebel

[1]: https://github.com/vdemedes/express-errors

[2]: https://github.com/expressjs/errorhandler

[3]: https://github.com/trygve-lie/express-error-responses/blob/master/lib/middleware.js

[4]: https://github.com/restify/errors
