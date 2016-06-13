{beforeEach, describe, it} = global

mongojs = require 'mongojs'
redis   = require 'ioredis'
ConfigurationRetriever = require '../'

describe 'when the flow-id/instance-id is not in the cache or the datastore', ->
  beforeEach 'connect to cache', (done) ->
    @cache = redis.createClient()
    @cache.del 'flow-id', done

  beforeEach 'connect to datastore', (done) ->
    @mongoClient = mongojs 'localhost/nanocyte-configuration-retriever-test', ['instances']
    @datastore   = @mongoClient.instances
    @datastore.remove done


  it 'should just pass right on through', (done) ->
    sut = new ConfigurationRetriever cache: @cache, datastore: @datastore
    sut.synchronizeByFlowIdAndInstanceId 'flow-id', 'instance-id', done
