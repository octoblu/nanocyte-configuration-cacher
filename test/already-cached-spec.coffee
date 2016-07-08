{beforeEach, describe, it} = global
{expect} = require 'chai'

mongojs = require 'mongojs'
redis   = require 'ioredis'
ConfigurationRetriever = require '../'
crypto = require 'crypto'

hash = (flowData) -> crypto.createHash('sha256').update(flowData).digest 'hex'

describe 'Already cached', ->

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

    @theHash = hash(flowData)

    @datastore.insert {
      flowId: 'flow-id'
      instanceId: 'instance-id'
      flowData: flowData
      hash: @theHash
    }, done


  beforeEach 'connect to cache', (done) ->
    @cache = redis.createClient()
    @cache.hset 'flow-id', "instance-id/hash/#{@theHash}", Date.now(), done

  beforeEach 'synchronizeByFlowIdAndInstanceId', (done) ->
    @sut = new ConfigurationRetriever {@cache, @datastore}
    @sut.synchronizeByFlowIdAndInstanceId 'flow-id', 'instance-id', done

  it 'should not cache the flow', (done) ->
    @cache.hget 'flow-id', 'instance-id/node-id/config', (error, result) =>
      expect(result).not.to.exist
      done()
