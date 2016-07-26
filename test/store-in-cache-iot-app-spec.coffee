{beforeEach, describe, it} = global
{expect} = require 'chai'

mongojs = require 'mongojs'
redis   = require 'ioredis'
ConfigurationRetriever = require '../'
crypto = require 'crypto'

hash = (flowData) -> crypto.createHash('sha256').update(flowData).digest 'hex'

describe 'Store in Cache IoT App', ->
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
          version: '1'
          appId: 'the-app-id'
      'node-id':
        config: {foo: 'bar'}
        data:   {bar: 'foo'}


    @theHash = hash(flowData)

    @datastore.insert {
      flowId: 'flow-id'
      instanceId: 'instance-id'
      flowData: flowData
      hash: @theHash,
      bluprint:
        appId: 'the-app-id'
        version: '1'
    }, done

  beforeEach 'insert bluprint', (done) ->
    flowData = JSON.stringify
      'node-id':
        config: {foo: 'bar'}
        data:   {bar: 'foo'}


    @iotAppHash = hash flowData
    @datastore.insert {
      appId: 'the-app-id'
      version: '1'
      flowData: flowData
      hash: @iotAppHash
    }, done

  beforeEach 'synchronizeByFlowIdAndInstanceId', (done) ->
    @sut = new ConfigurationRetriever cache: @cache, datastore: @datastore
    @sut.synchronizeByFlowIdAndInstanceId 'flow-id', 'instance-id', done

  it 'should create an instance-id key', (done) ->
    @cache.hexists 'bluprint/the-app-id', "1/hash/#{@iotAppHash}", (error, exist) =>
      return done error if error?
      expect(exist).to.equal 1
      done()

  it 'should cache the flow config configuration', (done) ->
    @cache.hget 'bluprint/the-app-id', '1/node-id/config', (error, config) =>
      return done error if error?
      expect(config).to.deep.equal '{"foo":"bar"}'
      done()

  it 'should cache the flow data configuration', (done) ->
    @cache.hget 'bluprint/the-app-id', '1/node-id/data', (error, data) =>
      return done error if error?
      expect(data).to.deep.equal '{"bar":"foo"}'
      done()

  describe 'when the bluprint changes in mongo', ->
    beforeEach 'alter the bluprint in mongo', (done) ->
      flowData = JSON.stringify
        'a-different-node':
          config: {different: 'stuff'}
          data:   {every: 'where'}


      @newIotAppHash = hash flowData
      @datastore.update(
        {appId: 'the-app-id'},
        {
          appId: 'the-app-id'
          version: '1'
          flowData: flowData
          hash: @newIotAppHash
        }
        done
      )

    beforeEach 'synchronizeByFlowIdAndInstanceId', (done) ->
      @sut = new ConfigurationRetriever cache: @cache, datastore: @datastore
      @sut.synchronizeByFlowIdAndInstanceId 'flow-id', 'instance-id', done

    it 'should cache the new bluprint configuration', (done) ->
      @cache.hget 'bluprint/the-app-id', '1/a-different-node/data', (error, data) =>
        return done error if error?
        expect(data).to.deep.equal '{"every":"where"}'
        done()
