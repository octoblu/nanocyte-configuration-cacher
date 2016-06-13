{beforeEach, describe, it} = global
{expect} = require 'chai'

mongojs = require 'mongojs'
redis   = require 'ioredis'
ConfigurationRetriever = require '../'

describe 'Retrieve from Datastore', ->
  beforeEach 'connect to cache', (done) ->
    @cache = redis.createClient()
    @cache.del 'flow-id', done

  beforeEach 'connect to datastore', (done) ->
    @mongoClient = mongojs 'localhost/nanocyte-configuration-retriever-test', ['instances']
    @datastore   = @mongoClient.instances
    @datastore.remove done

  beforeEach 'insert instances', (done) ->
    @datastore.insert {
      flowId: 'flow-id'
      instanceId: 'instance-id'
      flowData: {foo: 'something'}
    }, done

  beforeEach 'synchronizeByFlowIdAndInstanceId', (done) ->
    @sut = new ConfigurationRetriever {@cache, @datastore}
    @sut.synchronizeByFlowIdAndInstanceId 'flow-id', 'instance-id', (error, @configuration) => done error

  it 'should yield the flow configuration', ->
    expect(@configuration).to.deep.equal foo: 'something'
