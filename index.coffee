errorHandler = require './errorHandler'

module.exports = {
  Wx: require './wx'
  WxQy: require './wxqy'
  WxHttpError: errorHandler.WxHttpError
  WxError: errorHandler.WxError
}