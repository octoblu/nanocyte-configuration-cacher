{describe, it} = global
{expect} = require 'chai'

ConfigurationRetriever = require '../'

describe 'bad-instantiation', ->
  describe 'when instantiated without a cache', ->
    it 'should throw', ->
      expect(=> new ConfigurationRetriever datastore: {}).to.throw 'cache is required'

  describe 'when instantiated without a datastore', ->
    it 'should throw', ->
      expect(=> new ConfigurationRetriever cache: {}).to.throw 'datastore is required'
