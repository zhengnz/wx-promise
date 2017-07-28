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

class Wx
  constructor: (@id, @secret, @encrypt_key=null, @cache=new Cache(), @mch_id=null, @cert_path=null) ->
  # mch_id 商户id，支付必须
  # encrypt_key 加密字符串，必须使用32位，该字符串需与微信后台Token一致

  get_sign: (obj, key=null) ->
    obj = _.clone obj
    if _.has obj, 'sign'
      delete obj.sign
    s = _.keys(obj).sort().map (k) ->
      if typeof obj[k] is 'object'
        "#{k}=#{obj[k]._cdata}"
      else if not obj[k]
        false
      else
        "#{k}=#{obj[k]}"
    .filter (result) ->
      result
    .join '&'
    if key is null
      key = @encrypt_key
    s = "#{s}&key=#{key}"
    utils.md5(s).toUpperCase()

  nonce_str: ->
    utils.randomString(32, '1234567890abcdefghijklmnopqrstuvwxyz').toUpperCase()

  #获取跳转的微信登陆地址
  auth_url: (redirect_uri, state, scope='snsapi_base') ->
    url = 'https://open.weixin.qq.com/connect/oauth2/authorize'
    url = "#{url}?appid=#{@id}"
    url = "#{url}&redirect_uri=#{utils.encodeURIComponent redirect_uri}"
    "#{url}&response_type=code&scope=#{scope}&state=#{state}#wechat_redirect"

  #登录
  login: (code) ->
    url = "https://api.weixin.qq.com/sns/oauth2/access_token?appid=#{@id}&secret=#{@secret}&code=#{code}&grant_type=authorization_code"
    rp {
      uri: url
      json: true
    }
    .then (request) ->
      if _.has request, 'errcode'
        Promise.reject new WxError request.errmsg
      else
        Promise.resolve request

  #获取用户信息
  user_info: (token, openid) ->
    url = "https://api.weixin.qq.com/sns/userinfo?access_token=#{token}&openid=#{openid}&lang=zh_CN"
    rp {
      uri: url
      json: true
    }
    .then (request) ->
      if _.has request, 'errcode'
        Promise.reject new WxError request.errmsg
      else
        Promise.resolve request

  #获取access_token
  access_token: ->
    @cache.get 'access_token'
    .then (token) =>
      if token?
        return Promise.resolve token
      uri = "https://api.weixin.qq.com/cgi-bin/token"
      rp {
        uri: uri
        qs:
          grant_type: 'client_credential'
          appid: @id
          secret: @secret
        json: true
      }
      .then (req) =>
        if _.has req, 'errcode'
          Promise.reject new WxError req.errmsg
        else
          @cache.set 'access_token', req.access_token, req.expires_in - 60

  #自定义菜单
  create_menu: (json) ->
    uri = 'https://api.weixin.qq.com/cgi-bin/menu/create'
    @access_token()
    .then (token) ->
      rp {
        uri: uri
        method: 'POST'
        qs:
          access_token: token
        body: json
        json: true
      }
    .then (req) ->
      if req.errmsg isnt 'ok'
        Promise.reject new WxError req.errmsg
      else
        Promise.resolve()

  #获取js接口的ticket
  jsapi_ticket: ->
    @cache.get 'jsapi_ticket'
    .then (ticket) =>
      if ticket?
        return Promise.resolve ticket
      uri = "https://api.weixin.qq.com/cgi-bin/ticket/getticket"
      @access_token().then (token) ->
        rp {
          uri: uri
          qs:
            access_token: token
            type: 'jsapi'
          json: true
        }
      .then (req) =>
        if req.errmsg isnt 'ok'
          Promise.reject new WxError req.errmsg
        else
          @cache.set 'jsapi_ticket', req.ticket, 7140

  #获取js接口签名
  js_signature: (url) ->
    @jsapi_ticket().then (ticket) ->
      letter =  _.map _.range(65, 91), (v) ->
        String.fromCharCode v
      letter_small = _.map letter, (v) ->
        v.toLowerCase()
      s = [
        letter.join('')
        letter_small.join('')
        _.range(0, 10).join('')
      ]
      noncestr = utils.randomString 16, s.join('')
      timestamp = moment().format('X')
      s = "jsapi_ticket=#{ticket}&noncestr=#{noncestr}&timestamp=#{timestamp}&url=#{url}"
      signature = utils.sha1 s
      {
        noncestr: noncestr
        timestamp: timestamp
        signature: signature
      }

  #模板信息功能
  temp_info: (openid, tid, data, url=null) ->
    uri = 'https://api.weixin.qq.com/cgi-bin/message/template/send'
    @access_token().then (token) ->
      rp {
        uri: uri
        method: 'POST'
        qs:
          access_token: token
        body:
          touser: openid
          template_id: tid
          url: url
          data: data
        json: true
      }
      .then (req) ->
        if req.errmsg isnt 'ok'
          Promise.reject new WxError req.errmsg
        else
          Promise.resolve true

  #下载媒体资源
  download: (media_id) ->
    uri = 'http://file.api.weixin.qq.com/cgi-bin/media/get'
    @access_token().then (token) ->
      rp {
        uri: uri
        qs:
          access_token: token
          media_id: media_id
        encoding: null
        resolveWithFullResponse: true
      }
      .then (response) ->
        if response.statusCode isnt 200
          Promise.reject new WxHttpError response.statusCode
        else if response.headers['content-type'] is 'text/plain'
          req = JSON.parse response.body.toString()
          Promise.reject new WxError req.errmsg
        else
          Promise.resolve response

  xml_parser: (s) ->
    xml_parser.parseStringAsync s
    .then (result) ->
      xml = result.xml
      _.forIn xml, (v, k) ->
        xml[k.toLowerCase()] = v[0]
      Promise.resolve xml

  o2l: (o) ->
    data = []
    _.forIn o, (v, k) ->
      _obj = {}
      _obj[k] = v
      data.push _obj
    data

  xml_creator: (obj) ->
    data = @o2l obj
    xml_creator {
      xml: data
    }

  #创建订单
  unified_order: (name, number, price, buyer_openid, notify_url, ip) ->
    uri = 'https://api.mch.weixin.qq.com/pay/unifiedorder'
    xml = {
      appid: @id
      mch_id: @mch_id
      nonce_str: @nonce_str()
      body: name #project name
      out_trade_no: number
      total_fee: _.multiply price, 100
      spbill_create_ip: ip
      notify_url: notify_url
      trade_type: 'JSAPI'
      openid: buyer_openid
    }
    xml.sign = @get_sign xml
    xml = @xml_creator xml
    rp {
      uri: uri
      method: 'POST'
      body: xml
      encoding: null
      resolveWithFullResponse: true
    }
    .then (response) =>
      if response.statusCode isnt 200
        Promise.reject new WxHttpError response.statusCode
      else
        @xml_parser response.body.toString()
        .then (xml) =>
          if xml.return_code is 'SUCCESS' and @get_sign(xml) is xml.sign
            if xml.result_code is 'SUCCESS'
              Promise.resolve xml
            else
              Promise.reject new WxError xml.err_code_des
          else
            Promise.reject new WxError xml.return_msg

  #关闭订单
  close_order: (number) ->
    uri = 'https://api.mch.weixin.qq.com/pay/closeorder'
    xml = {
      appid: @id
      mch_id: @mch_id
      nonce_str: @nonce_str()
      out_trade_no: number
    }

    xml.sign = @get_sign xml
    xml = @xml_creator xml
    rp {
      uri: uri
      method: 'POST'
      body: xml
      encoding: null
      resolveWithFullResponse: true
    }
    .then (response) =>
      if response.statusCode isnt 200
        Promise.reject new WxHttpError response.statusCode
      else
        @xml_parser response.body.toString()
        .then (xml) =>
          if xml.return_code is 'SUCCESS' and @get_sign(xml) is xml.sign
            if xml.result_code is 'SUCCESS'
              Promise.resolve xml
            else
              Promise.reject new WxError xml.err_code_des
          else
            Promise.reject new WxError xml.return_msg

  #退款
  refund: (number, price, refund_price) ->
    uri = 'https://api.mch.weixin.qq.com/secapi/pay/refund'
    xml = {
      appid: @id
      mch_id: @mch_id
      nonce_str: @nonce_str()
      out_trade_no: number
      out_refund_no: number
      total_fee: _.multiply price, 100
      refund_fee: _.multiply refund_price, 100
      op_user_id: @mch_id
    }

    xml.sign =  @get_sign xml
    xml = @xml_creator xml
    rp {
      uri: uri
      method: 'POST'
      body: xml
      encoding: null
      resolveWithFullResponse: true
      agentOptions:
        pfx: fs.readFileSync(@cert_path)
        passphrase: @mch_id
    }
    .then (response) =>
      if response.statusCode isnt 200
        Promise.reject new WxHttpError response.statusCode
      else
        @xml_parser response.body.toString()
        .then (xml) =>
          if xml.return_code is 'SUCCESS' and @get_sign(xml) is xml.sign
            if xml.result_code is 'SUCCESS'
              Promise.resolve xml
            else
              Promise.reject new WxError xml.err_code_des
          else
            Promise.reject new WxError xml.return_msg

  #检查订单状态
  check_pay: (out_trade_no) ->
    uri = 'https://api.mch.weixin.qq.com/pay/orderquery'
    xml = {
      appid: @id
      mch_id: @mch_id
      out_trade_no: out_trade_no
      nonce_str: @nonce_str()
    }
    xml.sign = @get_sign xml
    xml = @xml_creator xml
    rp {
      uri: uri
      method: 'POST'
      body: xml
      encoding: null
      resolveWithFullResponse: true
    }
    .then (response) =>
      if response.statusCode isnt 200
        Promise.reject new WxHttpError response.statusCode
      else
        @xml_parser response.body.toString()
        .then (xml) =>
          if xml.return_code is 'SUCCESS' and @get_sign(xml) is xml.sign
            if xml.result_code is 'SUCCESS'
              Promise.resolve xml
            else
              Promise.reject new WxError xml.err_code_des
          else
            Promise.reject new WxError xml.return_msg

  #发红包
  hb: (number, openid, price, send_name, wishing, act_name, remark, ip) ->
    uri = 'https://api.mch.weixin.qq.com/mmpaymkttransfers/sendredpack'
    xml = {
      wxappid:
        _cdata: @id
      mch_id:
        _cdata: @mch_id
      nonce_str:
        _cdata: @nonce_str()
      mch_billno:
        _cdata: number
      send_name:
        _cdata: send_name
      re_openid:
        _cdata: openid
      total_amount:
        _cdata: price * 100
      total_num:
        _cdata: 1
      wishing:
        _cdata: wishing
      client_ip:
        _cdata: ip
      act_name:
        _cdata: act_name
      remark:
        _cdata: remark
    }

    xml.sign = {
      _cdata: @get_sign xml
    }
    xml = @xml_creator xml
    rp {
      uri: uri
      method: 'POST'
      body: xml
      encoding: null
      resolveWithFullResponse: true
      agentOptions:
        pfx: fs.readFileSync(@cert_path)
        passphrase: @mch_id
    }
    .then (response) =>
      if response.statusCode isnt 200
        Promise.reject new HttpError response.statusCode
      else
        @xml_parser response.body.toString()
        .then (xml) =>
          console.log xml
          if xml.return_code is 'SUCCESS'
            if xml.result_code is 'SUCCESS'
              Promise.resolve xml
            else if xml.err_code_des is 'SYSTEMERROR'
              Promise.resolve xml
            else
              Promise.reject new WechatError xml.err_code_des
          else
            Promise.reject new WechatError xml.return_msg

  #客服列表
  kflist: ->
    uri = 'https://api.weixin.qq.com/cgi-bin/customservice/getkflist'
    @access_token().then (token) ->
      rp {
        uri: uri
        qs:
          access_token: token
        json: true
      }

  #在线客服
  online_kflist: ->
    uri = 'https://api.weixin.qq.com/cgi-bin/customservice/getonlinekflist'
    @access_token().then (token) ->
      rp {
        uri: uri
        qs:
          access_token: token
        json: true
      }

  #创建客服与用户的会话
  create_talk: (kf_account, openid) ->
    uri = 'https://api.weixin.qq.com/customservice/kfsession/create'
    @access_token().then (token) ->
      rp {
        uri: uri
        method: 'POST'
        qs:
          access_token: token
        body:
          kf_account: kf_account
          openid: openid
        json: true
      }
    .then (req) ->
      if req.errmsg is 'ok'
        Promise.resolve()
      else
        Promise.reject req.errmsg

module.exports = Wx