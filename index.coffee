async = require 'async'
_     = require 'lodash'

class ConfigurationRetriever
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
    @cache.hexists flowId, instanceId, (error, result) =>
      return callback error if error?
      callback null, (result == 1)

  _storeInCache: (record, callback) =>
    {flowId, instanceId, flowData} = record

    @_storeNodesInCache {flowId, instanceId, flowData}, (error) =>
      return callback error if error?
      @_storeInstanceId {flowId, instanceId}, callback

  _storeInstanceId: ({flowId, instanceId}, callback) =>
    @cache.hset flowId, instanceId, Date.now(), callback

  _storeNodesInCache: ({flowId, instanceId, flowData}, callback) =>
    flowData = JSON.parse flowData

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

module.exports = ConfigurationRetriever
