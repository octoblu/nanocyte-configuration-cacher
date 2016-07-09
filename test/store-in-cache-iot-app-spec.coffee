{beforeEach, describe, it} = global
{expect} = require 'chai'

mongojs = require 'mongojs'
redis   = require 'ioredis'
ConfigurationRetriever = require '../'
crypto = require 'crypto'

hash = (flowData) -> crypto.createHash('sha256').update(flowData).digest 'hex'

describe 'Store in Cache', ->
  beforeEach 'connect to cache', (done) ->
    @cache = redis.createClient()
    @cache.del 'flow-id',  =>
      @cache.del 'the-app-id', done

  beforeEach 'connect to datastore', (done) ->
    @mongoClient = mongojs 'localhost/nanocyte-configuration-retriever-test', ['instances']
    @datastore   = @mongoClient.instances
    @datastore.remove done

  beforeEach 'insert instances', (done) ->
    flowData = JSON.stringify
      bluprint:
        config:
          version: '1.0.0'
          appId: 'the-app-id'
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

  beforeEach 'insert bluprint', (done) ->
    flowData = JSON.stringify
      'node-id':
        config: {foo: 'bar'}
        data:   {bar: 'foo'}


    @iotAppHash = hash(flowData)
    @datastore.insert {
      flowId: 'the-app-id'
      instanceId: '1.0.0'
      flowData: flowData
      hash: @iotAppHash
    }, done

  beforeEach 'synchronizeByFlowIdAndInstanceId', (done) ->
    @sut = new ConfigurationRetriever cache: @cache, datastore: @datastore
    @sut.synchronizeByFlowIdAndInstanceId 'flow-id', 'instance-id', done

  it 'should create an instance-id key', (done) ->
    @cache.hexists 'the-app-id', "1.0.0/hash/#{@iotAppHash}", (error, exist) =>
      return done error if error?
      expect(exist).to.equal 1
      done()

  it 'should cache the flow config configuration', (done) ->
    @cache.hget 'the-app-id', '1.0.0/node-id/config', (error, config) =>
      return done error if error?
      expect(config).to.deep.equal '{"foo":"bar"}'
      done()

  it 'should cache the flow data configuration', (done) ->
    @cache.hget 'the-app-id', '1.0.0/node-id/data', (error, data) =>
      return done error if error?
      expect(data).to.deep.equal '{"bar":"foo"}'
      done()
