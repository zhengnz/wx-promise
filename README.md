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
        return this.cache.setAsync(key, val, time).then(function() {
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

***待补充...***