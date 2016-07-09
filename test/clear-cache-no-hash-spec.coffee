{beforeEach, describe, it} = global
{expect} = require 'chai'

mongojs = require 'mongojs'
redis   = require 'ioredis'
ConfigurationRetriever = require '../'

describe 'Clear cache with no hash', ->

  beforeEach 'connect to datastore', (done) ->
    @mongoClient = mongojs 'localhost/nanocyte-configuration-retriever-test', ['instances']
    @datastore   = @mongoClient.instances
    @datastore.remove done

  afterEach 'clean up mongo', (done) ->
    @cache = redis.createClient()
    @cache.del 'flow-id', done

  beforeEach 'insert instances', (done) ->
    flowData = JSON.stringify
      'node-id':
        config: {foo: 'bar'}
        data:   {bar: 'foo'}

    @datastore.insert {
      flowId: 'flow-id'
      instanceId: 'instance-id'
      flowData: flowData

    }, done

  beforeEach 'connect to cache', (done) ->
    @cache = redis.createClient()
    @cache.hset 'flow-id', 'instance-id', Date.now(), done

  beforeEach 'clearByFlowIdAndInstanceId', (done) ->  
    @sut = new ConfigurationRetriever {@cache, @datastore}
    @sut.clearByFlowIdAndInstanceId 'flow-id', 'instance-id', done

  it 'should delete the key in redis', (done) ->
    @cache.hget 'flow-id', 'instance-id', (error, result) =>
      expect(result).not.to.exist
      done()
