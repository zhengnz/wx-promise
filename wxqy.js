// Generated by CoffeeScript 1.10.0
(function() {
  var Cache, Promise, WxError, WxHttpError, WxQy, _, errorHandler, fs, moment, rp, utils, xml_creator, xml_parser;

  utils = require('utility');

  rp = require('request-promise');

  _ = require('lodash');

  Promise = require('bluebird');

  moment = require('moment');

  xml_creator = require('xml');

  xml_parser = require('xml2js');

  fs = require('fs');

  Cache = require('./cache');

  errorHandler = require('./errorHandler');

  Promise.promisifyAll(xml_parser);

  WxHttpError = errorHandler.WxHttpError;

  WxError = errorHandler.WxError;

  WxQy = (function() {
    function WxQy(corp_id, secret, provider_secret, cache) {
      this.corp_id = corp_id;
      this.secret = secret;
      this.provider_secret = provider_secret;
      this.cache = cache != null ? cache : new Cache();
    }

    WxQy.prototype.auth_url = function(redirect_uri, state) {
      redirect_uri = encodeURIComponent(redirect_uri);
      return "https://qy.weixin.qq.com/cgi-bin/loginpage?corp_id=" + this.corp_id + "&redirect_uri=" + redirect_uri + "&state=" + state + "&usertype=member";
    };

    WxQy.prototype.access_token = function() {
      return this.cache.get('access_token').then((function(_this) {
        return function(token) {
          var uri;
          if (token != null) {
            return Promise.resolve(token);
          }
          uri = "https://qyapi.weixin.qq.com/cgi-bin/gettoken";
          return rp({
            uri: uri,
            qs: {
              corpid: _this.corp_id,
              corpsecret: _this.secret
            },
            json: true
          }).then(function(req) {
            if (_.has(req, 'errcode')) {
              return Promise.reject(new WxError(req.errmsg));
            } else {
              return _this.cache.set('access_token', req.access_token, req.expires_in - 60);
            }
          });
        };
      })(this));
    };

    WxQy.prototype.provider_access_token = function() {
      return this.cache.get('provider_access_token').then((function(_this) {
        return function(token) {
          var uri;
          if (token != null) {
            return Promise.resolve(token);
          }
          uri = "https://qyapi.weixin.qq.com/cgi-bin/service/get_provider_token";
          return rp({
            uri: uri,
            method: 'POST',
            body: {
              corpid: _this.corp_id,
              provider_secret: _this.provider_secret
            },
            json: true
          }).then(function(req) {
            if (_.has(req, 'errcode')) {
              return Promise.reject(new WxError(req.errmsg));
            } else {
              return _this.cache.set('provider_access_token', req.provider_access_token, req.expires_in - 60);
            }
          });
        };
      })(this));
    };

    WxQy.prototype.user_info = function(code, is_provider) {
      var uri;
      if (is_provider == null) {
        is_provider = false;
      }
      uri = 'https://qyapi.weixin.qq.com/cgi-bin/service/get_login_info';
      return Promise.resolve(is_provider === false ? this.access_token() : this.provider_access_token()).then(function(token) {
        return rp({
          uri: uri,
          method: 'POST',
          qs: {
            access_token: token
          },
          body: {
            auth_code: code
          },
          json: true
        });
      }).then(function(request) {
        if (_.has(request, 'errcode')) {
          return Promise.reject(new WxError(request.errmsg));
        } else {
          return Promise.resolve(request);
        }
      });
    };

    return WxQy;

  })();

  module.exports = WxQy;

}).call(this);

//# sourceMappingURL=wxqy.js.map
