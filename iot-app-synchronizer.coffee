async = require 'async'
_     = require 'lodash'

class IotAppSynchronizer
  constructor: ({@cache, @datastore}) ->
    throw new Error 'cache is required' unless @cache?
    throw new Error 'datastore is required' unless @datastore?

  synchronizeByAppIdAndVersion: (appId, version, callback) =>
    @_isCached {appId, version}, (error, cached) =>
      return callback error if error?
      return callback() if cached

      @datastore.findOne {appId, version}, (error, record) =>
        return callback error if error?
        return callback() unless record?

        @_storeInCache record, (error) =>
          return callback error if error?
          return callback null

  _isCached: ({appId, version}, callback) =>
    @datastore.findOne {appId, version}, {hash: true}, (error, {hash}={}) =>
      return callback error if error?

      @cache.hexists "bluprint/#{appId}", "#{version}/hash/#{hash}", (error, result) =>
        return callback error if error?
        callback null, (result == 1)

  _storeInCache: (record, callback) =>
    {appId, version, flowData, hash} = record
    flowData = JSON.parse flowData

    @_storeNodesInCache {appId, version, flowData}, (error) =>
      return callback error if error?
      @_storeInstanceId {appId, version, hash}, (error) =>
        return callback error if error?
        {bluprint} = flowData

        return callback() unless bluprint?
        @synchronizeByAppIdAndVersion bluprint.config?.appId, bluprint.config?.version, callback

  _storeInstanceId: ({appId, version, hash}, callback) =>
    @cache.hset "bluprint/#{appId}", "#{version}/hash/#{hash}", Date.now(), callback

  _storeNodesInCache: ({appId, version, flowData}, callback) =>

    async.each _.keys(flowData), (key, next) =>
      nodeConfig = flowData[key]
      nodeConfig.data ?= {}
      nodeConfig.config ?= {}

      data = [
        "#{version}/#{key}/data", JSON.stringify nodeConfig.data
        "#{version}/#{key}/config", JSON.stringify nodeConfig.config
      ]

      @cache.hmset "bluprint/#{appId}", data..., next

    , callback

  clearByAppIdAndVersionId: (appId, version, callback) =>
    @datastore.findOne {appId, version}, {hash: true}, (error, {hash}={}) =>
      return @cache.hdel "bluprint/#{appId}", version, callback unless hash?
      @cache.hdel "bluprint/#{appId}", "#{version}/hash/#{hash}", callback

module.exports = IotAppSynchronizer
