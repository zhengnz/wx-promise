conf = {
  id: null
  secret: null
  encrpyt_key: null
  mch_id: null
  download: null #如需测试下载静态资源，请在此处写入media_id
  test_temp: [] #如需测试模板消息，请在此处写入信息[收信人openid, 模板id, 模板数据, 模板跳转链接]
}

if conf.id is null or conf.secret is null
  throw Error 'id and secret is require'

module.exports = conf