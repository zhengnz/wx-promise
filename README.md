**该版本是从我的正式项目迁移过来，在项目里已经可以运行，目前迁移后暂未测试，平时比较忙，如果有兴趣可以帮忙测试下，有问题发issue给我**

#初始化
---
    var wxp = require('wechat-promise');
    var wx = new wxp.Wx(app_id, app_secret, encrypt_key);
---

##自定义并加入缓存
**微信的access_token, js_ticket在正式生产环境中需要缓存起来，所以wechat-promise已内置自动缓存的调用，只需要自定义cache既可**

**cache的定义方法如下，以memcached为例**

---
    var memcached = new Memcahced(...),
        Promise = require('bluebird');
    var Cache = (function() {
      function Cache(cache) {
        this.cache = cache;
        Promise.promisifyAll(this.cache);
      }
    
      Cache.prototype.get = function(key) {
        return this.cache.getAsync(key);
      };
    
      Cache.prototype.set = function(key, value, expire) {
        return this.cache.setAsync(key, val, expire).then(function() {
          return Promise.resolve(val);
        });
      };
    
      return Cache;
    
    })();
    
    var cache = new Cache(memcached);
    var wx = new wxp.Wx(app_id, app_secret, encrypt_key, cache);
---

##启用支付功能
**添加商户id和证书地址**

**商户id和证书均可在微信商户平台获取**

---
    var wx = new wxp.Wx(app_id, app_secret, encrypt_key, cache, mch_id, cert_path);
---

#接口操作
##请边参考微信接口的文档边对照使用

###获取登录授权码链接
**auth_url**

**微信浏览器跳转到该链接后会跳转回redirect_url，并在链接上加上授权码code，通过code可进行登录操作**

---
    var url = wx.auth_url(redirect_url, state, scope);
---

###登录
**login**

**登录微信账号**

---
    wx.login(code).then(function(data){
      console.log(data.access_token);
      console.log(data.openid);
    });
---

###获取用户信息
**user_info**

**登录后获取用户信息，昵称头像等**

---
    wx.user_info(token, openid).then(function(data){
      console.log(data)
    });
---

###获取access_token
**access_token**

**用于其他接口调用的token，此token不同于登陆的access_token，请勿混淆**

**该token支持缓存，实际应用中也必须缓存，程序中已内置，但缓存方法需要自定义，请参考‘自定义并加入缓存’**

---
    wx.access_token().then(function(token){
      console.log(token);
    });
---

###自定义菜单
**create_menu**

**用于自定义进入公众号时底部菜单，使用该功能必须开启服务器配置**

**该方法的json参数请参照微信文档**

---
    wx.create_menu(json).then(function(data){
      console.log(data);
    });
---

###获取js接口签名
**js_signature**

**用于调用微信jssdk**

---
    console.log(wx.js_signature(url));
---

###模板接口
**temp_info**

**推送给指定用户信息**

---
    wx.temp_info(openid, tid, data, url).then(function(data){
      console.log(data);
    });
---

###下载媒体资源
**download**

**下载媒体资源，请注意媒体资源过期时间**

---
    wx.download(media_id).then(function(data){
      console.log(data);
    });
---

***待补充支付部分***