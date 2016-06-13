{beforeEach, describe, it} = global
{expect} = require 'chai'

mongojs = require 'mongojs'
redis   = require 'ioredis'
ConfigurationRetriever = require '../'

describe 'Store in Cache', ->
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
      flowData: JSON.stringify
        'node-id':
          config: {foo: 'bar'}
          data:   {bar: 'foo'}
    }, done

  beforeEach 'synchronizeByFlowIdAndInstanceId', (done) ->
    @sut = new ConfigurationRetriever cache: @cache, datastore: @datastore
    @sut.synchronizeByFlowIdAndInstanceId 'flow-id', 'instance-id', done

  it 'should cache the flow config configuration', (done) ->
    @cache.hget 'flow-id', 'instance-id/node-id/config', (error, config) =>
      return done error if error?
      expect(config).to.deep.equal '{"foo":"bar"}'
      done()

  it 'should cache the flow data configuration', (done) ->
    @cache.hget 'flow-id', 'instance-id/node-id/data', (error, data) =>
      return done error if error?
      expect(data).to.deep.equal '{"bar":"foo"}'
      done()
