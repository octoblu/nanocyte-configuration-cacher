{beforeEach, describe, it} = global
{expect} = require 'chai'

mongojs = require 'mongojs'
redis   = require 'ioredis'
ConfigurationRetriever = require '../'


describe 'Already cached without a hash', ->

  beforeEach 'connect to datastore', (done) ->
    @mongoClient = mongojs 'localhost/nanocyte-configuration-retriever-test', ['instances']
    @datastore   = @mongoClient.instances
    @datastore.remove done

  afterEach 'clean up mongo', (done) ->
    @cache = redis.createClient()
    @cache.del 'flow-id', done

  beforeEach 'connect to cache', (done) ->
    @cache = redis.createClient()
    @cache.hset 'flow-id', 'instance-id', Date.now(), done

  beforeEach 'synchronizeByFlowIdAndInstanceId', (done) ->    
    @sut = new ConfigurationRetriever {@cache, @datastore}
    @sut.synchronizeByFlowIdAndInstanceId 'flow-id', 'instance-id', done

  it 'should not notice that the datastore was an imposter', (done) ->
    @datastore.findOne {flowId: 'flow-id', instanceId: 'instance-id'}, (error, result) =>
      expect(result).not.to.exist
      done()
