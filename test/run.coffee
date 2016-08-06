wxp = require '../'
conf = require './config'
Promise = require 'bluebird'

wx = new wxp.Wx conf.id, conf.secret, conf.encrpyt_key, null, conf.mch_id
testing_func = null
arr = [
  ->
    testing_func = 'Access Token'
    wx.access_token().then (token) ->
      console.log "Test Access Token Success, Token: #{token}"
  ->
    testing_func = 'JS API Ticket'
    wx.jsapi_ticket().then (ticket) ->
      console.log "Test JS API Ticket Success, Ticket: #{ticket}"
]
if conf.test_temp.length
  f = ->
    testing_func = '模板信息'
    wx.temp_info conf.test_temp[0], conf.test_temp[1], conf.test_temp[2], conf.test_temp[3]
  arr.push f
if conf.download
  f = ->
    testing_func = '媒体下载'
    wx.download conf.download
  arr.push f

Promise.mapSeries arr, (p) ->
  Promise.resolve p()
.then ->
  console.log '100% Success'
.catch (err) ->
  console.log "#{testing_func}发生错误"
  console.log err.stack
.finally ->
  console.log 'Test Complete'