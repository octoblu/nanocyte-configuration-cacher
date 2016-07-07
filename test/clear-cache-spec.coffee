{beforeEach, describe, it} = global

redis   = require 'ioredis'
ConfigurationRetriever = require '../'

describe 'Already cached', ->
  beforeEach 'connect to cache', (done) ->
    @cache = redis.createClient()
    @cache.hset 'flow-id', 'instance-id', Date.now(), done

  beforeEach 'clearByFlowIdAndInstanceId', (done) ->
    @datastore = {}
    @sut = new ConfigurationRetriever {@cache, @datastore}
    @sut.clearByFlowIdAndInstanceId 'flow-id', 'instance-id', done

  it 'should delete the key in redis', (done) ->
    @cache.hget 'flow-id', 'instance-id', (error, result) =>
      expect(result).not.to.exist
      done()
