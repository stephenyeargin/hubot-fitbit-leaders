chai = require 'chai'
sinon = require 'sinon'
chai.use require 'sinon-chai'

expect = chai.expect

describe 'hubot-fitbit-leaders', ->
  beforeEach ->
    @robot =
      respond: sinon.spy()
      hear: sinon.spy()

    require('../src/hubot-fitbit-leaders')(@robot)

  it 'registers a respond listener for fitbit', ->
    expect(@robot.respond).to.have.been.calledWith(/fitbit$/i)

  it 'registers a respond listener for fitbit setup', ->
    expect(@robot.respond).to.have.been.calledWith(/fitbit (?:token|setup)$/i)

  it 'registers a respond listener for fitbit friends', ->
    expect(@robot.respond).to.have.been.calledWith(/fitbit friends/i)

  it 'registers a respond listener for fitbit approve', ->
    expect(@robot.respond).to.have.been.calledWith(/fitbit approve/i)

  it 'registers a respond listener for fitbit leaders', ->
    expect(@robot.respond).to.have.been.calledWith(/fitbit (steps|leaderboard|leaders)/i)
