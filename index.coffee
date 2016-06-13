async = require 'async'
_     = require 'lodash'

class ConfigurationRetriever
  constructor: ({@cache, @datastore}) ->

  synchronizeByFlowIdAndInstanceId: (flowId, instanceId, callback) =>
    @datastore.findOne {flowId, instanceId}, (error, record) =>
      return callback error if error?
      @_storeInCache record, (error) =>
        return callback error if error?
        return callback null, record.flowData

  _storeInCache: (record, callback) =>
    {flowId, instanceId, flowData} = record

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
