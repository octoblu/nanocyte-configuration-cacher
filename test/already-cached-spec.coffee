{beforeEach, describe, it} = global

redis   = require 'ioredis'
ConfigurationRetriever = require '../'

describe 'Already cached', ->
  beforeEach 'connect to cache', (done) ->
    @cache = redis.createClient()
    @cache.hset 'flow-id', 'instance-id', Date.now(), done

  beforeEach 'synchronizeByFlowIdAndInstanceId', ->
    @datastore = {}
    @sut = new ConfigurationRetriever {@cache, @datastore}

  it 'should not notice that the datastore was an imposter', (done) ->
    @sut.synchronizeByFlowIdAndInstanceId 'flow-id', 'instance-id', done
