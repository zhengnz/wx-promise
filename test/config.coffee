conf = {
  id: 'wx481c10d59e2815b9'
  secret: 'f4da79269d88c47b2040387e44882eda'
  encrpyt_key: 'GVOBHZZ1A3RRULTV71QF8ZNEQLU8153O'
  mch_id: '1340517601'
  download: null #如需测试下载静态资源，请在此处写入media_id
  test_temp: [] #如需测试模板消息，请在此处写入信息[收信人openid, 模板id, 模板数据, 模板跳转链接]
}

if conf.id is null or conf.secret is null
  throw Error 'id and secret is require'

module.exports = conf