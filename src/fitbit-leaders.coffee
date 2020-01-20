# Description:
#   Fitbit leaderboards
#
# Configuration:
#  FITBIT_CLIENT_ID
#  FITBIT_CLIENT_SECRET
#  FITBIT_OAUTH_TOKEN
#  FITBIT_REDIRECT_URL
#
# Commands:
#   hubot fitbit leaders - Show table of leaders
#   hubot fitbit register - Show how to friend the bot
#   hubot fitbit approve - Approve all pending requests
#
# Notes:
#   To obtain/set the FITBIT_OAUTH_TOKEN, you will need to visit the "Implicit"
#   authorization URL. This will grant you a non-refreshable token for a year.
#
# Authors:
#   stephenyeargin, hogepodge

Util = require 'util'
moment = require 'moment'

module.exports = (robot) ->
  FitbitApiClient = require 'fitbit-node'
  getFitbitClient = (apiVersion) ->
    new FitbitApiClient(
      clientId: process.env.FITBIT_CLIENT_ID,
      clientSecret: process.env.FITBIT_CLIENT_SECRET,
      apiVersion: apiVersion || '1.2'
    )
  accessToken = process.env.FITBIT_OAUTH_TOKEN
  redirectUri = process.env.FITBIT_REDIRECT_URL || 'http://localhost/'
  
  # Default action
  robot.respond /fitbit$/i, (msg) ->
    getLeaderboard(msg)
  
  # Set up or renew the token
  robot.respond /fitbit (?:token|setup)$/i, (msg) ->
    url = "" +
      "https://www.fitbit.com/oauth2/authorize?response_type=token" +
      "&client_id=#{process.env.FITBIT_CLIENT_ID}" +
      "&redirect_uri=#{redirectUri}" +
      "&scope=profile%20social&expires_in=31536000"
    msg.send """
       1) Go to: #{url}
       2) Save the URL token in the bot's configuration as FITBIT_OAUTH_TOKEN
       3) Restart Hubot to load configuration
    """
  
  # Show the top five users
  robot.respond /fitbit (steps|leaderboard|leaders)/i, (msg) ->
    getLeaderboard(msg)
  
  # Who are my friends?
  robot.respond /fitbit friends/i, (msg) ->
    getFitbitClient('1.1').get('/friends.json', accessToken)
    .then (res) ->
      responseBody = getResponseBody(res)
      responseHeaders = getResponseHeaders(res)
      return displayErrors(responseBody, msg) if responseHeaders.statusCode != 200
      friends = responseBody.data
      if friends.length > 0
        list = []
        for own key, friend of friends
          list.push "#{friend.attributes.name}"
        msg.send list.join(", ")
      else
        msg.send "You have no friends on Fitbit. :("
    .catch (error) ->
      displayErrors(error, msg)
  
  # See how to friend the bot
  robot.respond /fitbit register/i, (msg) ->
    getFitbitClient('1').get('/profile.json', accessToken)
    .then (res) ->
      responseBody = getResponseBody(res)
      responseHeaders = getResponseHeaders(res)
      return displayErrors(responseBody, msg) if responseHeaders.statusCode != 200
      user = responseBody.user
      unless user.fullName
        user.fullName = 'the bot'
      userId = user.encodedId
      msg.send """
        1) Add #{user.fullName} as a friend - http://fitbit.com/user/#{userId}
        2) Type `#{robot.name} fitbit approve`
      """
    .catch (error) ->
      displayErrors(error, msg)
  
  # Approve existing friend requests
  robot.respond /fitbit approve/i, (msg) ->
    getFitbitClient('1.1').get('/friends/invitations.json', accessToken)
    .then (res) ->
      responseBody = getResponseBody(res)
      responseHeaders = getResponseHeaders(res)
      return displayErrors(responseBody, msg) if responseHeaders.statusCode != 200
      if responseBody.data.length is 0
        msg.send "No pending requests."
        return
      for own key, friend of responseBody.included
        getFitbitClient('1.1').post(
          "/friends/invitations/#{friend.id}?accept=true",
          accessToken
        )
        .then (res) ->
          robot.logger.debug getResponseBody(res)
          msg.send "Approved: #{friend.attributes.name}"
        .catch (error) ->
          displayErrors(error, msg)
    .catch (error) ->
      displayErrors(error, msg)
  
  getLeaderboard = (msg) ->
    try
      getFitbitClient('1.1').get('/leaderboard/friends.json', accessToken)
      .then (res) ->
        responseBody = getResponseBody(res)
        responseHeaders = getResponseHeaders(res)
        return displayErrors(responseBody, msg) if responseHeaders.statusCode != 200
        leaders = responseBody.data
        relatedData = responseBody.included
        people = {}
        for person in relatedData
          people[person.id] = person
        finalLeaders = []
        for own key, leader of leaders
          if leader.attributes && leader.attributes['step-summary'] > 0
            rank = leader.attributes['step-rank']
            displayName = people[leader.id].attributes.name || 'Unknown'
            steps = formatThousands(leader.attributes['step-summary']) || 0
            finalLeaders[rank] = "##{rank} #{displayName} - #{steps}"
        msg.send finalLeaders.join("\n")
      .catch (error) ->
        displayErrors(error, msg)
    catch err
      msg.send "Unable to retrieve leaderboard."
  
  getResponseBody = (res) ->
    return res[0]
  
  getResponseHeaders = (res) ->
    return res[1]
  
  displayErrors = (err, msg) ->
    robot.logger.debug err
    for own key, error of err.errors
      if error.errorType == 'expired_token'
        msg.send "Your Fitbit token has expired! See `#{robot.name} fitbit token` to set up a new one."
      else
        robot.logger.error err
        msg.send error.message
  
  formatThousands = (num) ->
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
