errorHandler = require './errorHandler'

module.exports = {
  Wx: require './wx'
  wxQy: require './wxqy'
  WxHttpError: errorHandler.WxHttpError
  WxError: errorHandler.WxError
}