Helper = require('hubot-test-helper')
chai = require 'chai'
nock = require 'nock'

expect = chai.expect

helper = new Helper('../src/fitbit-leaders.coffee')

describe 'hubot-fitbit-leaders', ->
  beforeEach ->
    process.env.HUBOT_LOG_LEVEL = 'error'
    nock.disableNetConnect()

    nock('https://api.fitbit.com:443')
      .get('/1.2/user/-/friends/leaderboard.json')
      .replyWithFile(200, __dirname + '/fixtures/leaderboard.json')
    nock('https://api.fitbit.com:443')
      .get('/1.2/user/-/profile.json')
      .replyWithFile(200, __dirname + '/fixtures/profile.json')
    nock('https://api.fitbit.com:443')
      .get('/1.2/user/-/friends.json')
      .replyWithFile(200, __dirname + '/fixtures/friends.json')
    nock('https://api.fitbit.com:443')
      .get('/1.2/user/-/friends/invitations.json')
      .replyWithFile(200, __dirname + '/fixtures/invitations.json')
    nock('https://api.fitbit.com:443')
      .post('/1.2/user/-/friends/invitations/257V3V.json')
      .replyWithFile(200, __dirname + '/fixtures/invitations-257V3V.json')

  afterEach ->
    nock.cleanAll()
    delete process.env.HUBOT_LOG_LEVEL

  context 'basic tests', ->
    beforeEach ->
      process.env.FITBIT_CLIENT_ID = 'abc123'
      process.env.FITBIT_CLIENT_SECRET = '123abc456efg'
      process.env.FITBIT_OAUTH_TOKEN = 'hijk123abc456efg789lmnop'
      @room = helper.createRoom()

    afterEach ->
      @room.destroy()
      delete process.env.FITBIT_CLIENT_ID
      delete process.env.FITBIT_CLIENT_SECRET
      delete process.env.FITBIT_OAUTH_TOKEN

    # hubot fitbit leaders
    it 'returns the leaderboard of your friends', (done) ->
      selfRoom = @room
      selfRoom.user.say('alice', '@hubot fitbit leaders')
      setTimeout(() ->
        try
          expect(selfRoom.messages).to.eql [
            ['alice', '@hubot fitbit leaders']
            ['hubot', "\n#1 Nick - 56,000\n#2 Fitbit U. - 45,000"]
          ]
          done()
        catch err
          done err
        return
      , 1000)

    # hubot fitbit setup
    it 'returns setup instructions', (done) ->
      selfRoom = @room
      selfRoom.user.say('alice', '@hubot fitbit setup')
      setTimeout(() ->
        try
          expect(selfRoom.messages).to.eql [
            ['alice', '@hubot fitbit setup']
            ['hubot', '1) Go to: https://www.fitbit.com/oauth2/authorize?response_type=token&client_id=abc123&redirect_uri=<YOUR REDIRECT URL>&scope=profile%20social&expires_in=31536000']
            ['hubot', '2) Save the URL token in the bot\'s configuration']
            ['hubot', '3) Restart Hubot to load configuration']
          ]
          done()
        catch err
          done err
        return
      , 1000)

    # hubot fitbit register
    it 'returns registration instructions', (done) ->
      selfRoom = @room
      selfRoom.user.say('alice', '@hubot fitbit register')
      setTimeout(() ->
        try
          expect(selfRoom.messages).to.eql [
            ['alice', '@hubot fitbit register']
            ['hubot', '1) Add Fitbit as a friend - http://fitbit.com/user/257V3V\n2) Type `hubot fitbit approve`']
          ]
          done()
        catch err
          done err
        return
      , 1000)
    
    # hubot fitbit friends
    it 'returns a list of friends', (done) ->
      selfRoom = @room
      selfRoom.user.say('alice', '@hubot fitbit friends')
      setTimeout(() ->
        try
          expect(selfRoom.messages).to.eql [
            ['alice', '@hubot fitbit friends']
            ['hubot', 'Nick, Fitbit U.']
          ]
          done()
        catch err
          done err
        return
      , 1000)

    # hubot fitbit approve
    it 'approves pending friend requests', (done) ->
      selfRoom = @room
      selfRoom.user.say('alice', '@hubot fitbit approve')
      setTimeout(() ->
        try
          expect(selfRoom.messages).to.eql [
            ['alice', '@hubot fitbit approve']
            ['hubot', 'Approve: Nick']
          ]
          done()
        catch err
          done err
        return
      , 1000)
