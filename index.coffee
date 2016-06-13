async = require 'async'
_     = require 'lodash'

class ConfigurationRetriever
  constructor: ({@cache, @datastore}) ->

  synchronizeByFlowIdAndInstanceId: (flowId, instanceId, callback) =>
    @_isCached {flowId, instanceId}, (error, cached) =>
      return callback error if error?
      return callback() if cached

      @datastore.findOne {flowId, instanceId}, (error, record) =>
        return callback error if error?
        @_storeInCache record, (error) =>
          return callback error if error?
          return callback null

  _isCached: ({flowId, instanceId}, callback) =>
    @cache.hexists flowId, instanceId, (error, result) =>
      return callback error if error?
      callback null, (result == 1)

  _storeInCache: (record, callback) =>
    {flowId, instanceId, flowData} = record
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
