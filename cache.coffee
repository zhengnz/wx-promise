Promise = require 'bluebird'

class Cache
  get: (key) ->
    Promise.resolve null

  set: (key, value, expire) ->
    Promise.resolve value

module.exports = Cache