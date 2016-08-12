class WxHttpError extends Error
  constructor: (msg) ->
    @name = 'HttpError'
    @msg = msg

  toString: ->
    "#{@name}: #{@msg}"

class WxError extends WxHttpError
  constructor: (msg) ->
    @name = 'WxError'
    @msg = msg

module.exports.WxHttpError = WxHttpError
module.exports.WxError = WxError