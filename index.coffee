async = require 'async'
_     = require 'lodash'

IotAppSynchronizer = require './iot-app-synchronizer'

class ConfigurationSynchronizer
  constructor: ({@cache, @datastore}) ->
    throw new Error 'cache is required' unless @cache?
    throw new Error 'datastore is required' unless @datastore?

  synchronizeByFlowIdAndInstanceId: (flowId, instanceId, callback) =>
    @_isCached {flowId, instanceId}, (error, cached) =>
      return callback error if error?
      return callback() if cached

      @datastore.findOne {flowId, instanceId}, (error, record) =>
        return callback error if error?
        return callback() unless record?

        @_storeInCache record, (error) =>
          return callback error if error?
          return callback null

  _isCached: ({flowId, instanceId}, callback) =>
    @datastore.findOne {flowId, instanceId}, {hash: true, bluprint: true}, (error, {hash, bluprint}={}) =>

      return callback error if error?
      return @_oldIsCached({flowId, instanceId}, callback) unless hash?

      @cache.hexists flowId, "#{instanceId}/hash/#{hash}", (error, result) =>
        return callback error, (result == 1) unless bluprint?
        iotAppSynchronizer = new IotAppSynchronizer {@cache,@datastore}
        iotAppSynchronizer.synchronizeByAppIdAndVersion bluprint.appId, bluprint.version, (error) =>
          return callback error if error?
          callback null, (result == 1)

  _oldIsCached: ({flowId, instanceId}, callback) =>
     @cache.hexists flowId, instanceId, (error, result) =>
      return callback error if error?
      callback null, (result == 1)

  _storeInCache: (record, callback) =>
    {flowId, instanceId, flowData, hash} = record
    flowData = JSON.parse flowData

    @_storeNodesInCache {flowId, instanceId, flowData}, (error) =>
      return callback error if error?
      @_storeInstanceId {flowId, instanceId, hash}, callback
      
  _storeInstanceId: ({flowId, instanceId, hash}, callback) =>
    return @cache.hset flowId, instanceId, Date.now(), callback unless hash?
    @cache.hset flowId, "#{instanceId}/hash/#{hash}", Date.now(), callback

  _storeNodesInCache: ({flowId, instanceId, flowData}, callback) =>
    async.each _.keys(flowData), (key, next) =>
      nodeConfig = flowData[key]
      nodeConfig.data ?= {}
      nodeConfig.config ?= {}

      data = [
        "#{instanceId}/#{key}/data", JSON.stringify nodeConfig.data
        "#{instanceId}/#{key}/config", JSON.stringify nodeConfig.config
      ]

      @cache.hmset flowId, data..., next

    , callback

  clearByFlowIdAndInstanceId: (flowId, instanceId, callback) =>
    @datastore.findOne {flowId, instanceId}, {hash: true}, (error, {hash}={}) =>
      return @cache.hdel flowId, instanceId, callback unless hash?
      @cache.hdel flowId, "#{instanceId}/hash/#{hash}", callback

module.exports = ConfigurationSynchronizer
