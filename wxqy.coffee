utils = require 'utility'
rp = require 'request-promise'
_ = require 'lodash'
Promise = require 'bluebird'
moment = require 'moment'
xml_creator = require 'xml'
xml_parser = require 'xml2js'
fs = require 'fs'
Cache = require './cache'
errorHandler = require './errorHandler'
Promise.promisifyAll xml_parser

WxHttpError = errorHandler.WxHttpError
WxError = errorHandler.WxError

class WxQy
  constructor: (@corp_id, @secret, @cache=new Cache()) ->

  #获取跳转的微信登陆地址
  auth_url: (redirect_uri, state) ->
    redirect_uri = encodeURIComponent redirect_uri
    "https://qy.weixin.qq.com/cgi-bin/loginpage?corp_id=#{@corp_id}&redirect_uri=#{redirect_uri}&state=#{state}&usertype=member"

  access_token: ->
    @cache.get 'access_token'
    .then (token) =>
      if token?
        return Promise.resolve token
      uri = "https://qyapi.weixin.qq.com/cgi-bin/gettoken"
      rp {
        uri: uri
        qs:
          corpid: @corp_id
          corpsecret: @secret
        json: true
      }
      .then (req) =>
        if _.has req, 'errcode'
          Promise.reject new WxError req.errmsg
        else
          @cache.set 'access_token', req.access_token, req.expires_in - 60

  user_info: (code) ->
    uri = 'https://qyapi.weixin.qq.com/cgi-bin/service/get_login_info'
    @access_token()
    .then (token) ->
      console.log token
      rp {
        uri: uri
        method: 'POST'
        qs:
          access_token: token
        body:
          auth_code: code
        json: true
      }
    .then (request) ->
      if _.has request, 'errcode'
        Promise.reject new WxError request.errmsg
      else
        Promise.resolve request

module.exports = WxQy