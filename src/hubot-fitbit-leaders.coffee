# Description:
#   Fitbit leaderboards
#
# Dependencies:
#   "fitbit-js": "0.2.0"
#
# Configuration:
#  FITBIT_CLIENT_ID
#  FITBIT_CLIENT_SECRET
#  FITBIT_OAUTH_TOKEN
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
  Fitbit = new FitbitApiClient(
    process.env.FITBIT_CLIENT_ID, process.env.FITBIT_CLIENT_SECRET
  )
  accessToken = process.env.FITBIT_OAUTH_TOKEN

  # Default action
  robot.respond /fitbit$/i, (msg) ->
    getLeaderboard(msg)

  # Set up or renew the token
  robot.respond /fitbit (?:token|setup)$/i, (msg) ->
    url = "" +
      "https://www.fitbit.com/oauth2/authorize?response_type=token" +
      "&client_id=#{process.env.FITBIT_CLIENT_ID}" +
      "&redirect_uri=<YOUR REDIRECT URL>" +
      "&scope=profile%20social&expires_in=31536000"
    msg.send "1) Go to: #{url}"
    msg.send "2) Save the URL token in the bot's configuration"
    msg.send "3) Restart Hubot to load configuration"

  # Show the top five users
  robot.respond /fitbit (steps|leaderboard|leaders)/i, (msg) ->
    getLeaderboard(msg)

  # Who are my friends?
  robot.respond /fitbit friends/i, (msg) ->
    Fitbit.get('/friends.json', accessToken)
    .then (res) ->
      robot.logger.debug res
      friends = getResponseBody(res).friends
      if friends.length > 0
        list = []
        for own key, friend of friends
          list.push "#{friend.user.displayName}"
        msg.send list.join(", ")
      else
        msg.send "You have no friends on Fitbit. :("
    .catch (error) ->
      displayErrors(error, msg)

  # See how to friend the bot
  robot.respond /fitbit register/i, (msg) ->
    Fitbit.get('/profile.json', accessToken)
    .then (res) ->
      robot.logger.debug res
      user = getResponseBody(res).user
      unless user.fullName
        user.fullName = 'the bot'
      msg.send "1) Add #{user.fullName} as a friend - http://fitbit.com/user/#{user.encodedId}\n2) Type `#{robot.name} fitbit approve`"
    .catch (error) ->
      displayErrors(error, msg)

  # Approve existing friend requests
  robot.respond /fitbit approve/i, (msg) ->
    Fitbit.get('/friends/invitations.json', accessToken)
    .then (res) ->
      robot.logger.debug res
      if getResponseBody(res).friends.length is 0
        msg.send "No pending requests."
        return
      for own key, friend of getResponseBody(res).friends
        params =
          accept: true
        Fitbit.post("/friends/invitations/#{friend.user.encodedId}.json", accessToken, params)
        .then (res) ->
          msg.send "Approve: #{friend.user.displayName}"
        .catch (error) ->
          displayErrors(error, msg)
    .catch (error) ->
      displayErrors(error, msg)

  getLeaderboard = (msg) ->
    try
      Fitbit.get('/friends/leaderboard.json', accessToken)
      .then (res) ->
        robot.logger.debug res
        leaders = getResponseBody(res).friends
        sortedleaders = []
        for own key, leader of leaders
          robot.logger.debug leader
          if leader.summary.steps > 0
            # Show a time-ago if user hasn't synced
            if moment(leader.lastUpdateTime) < moment().subtract(1, 'days')
              last_sync = " (#{moment(leader.lastUpdateTime).fromNow()})"
            else
              last_sync = ''
            rank = leader.rank.steps * 1 # force conversion to a number
            sortedleaders[rank] = "##{leader.rank.steps} #{leader.user.displayName} - #{formatThousands(leader.summary.steps)}#{last_sync}"
        msg.send sortedleaders.join("\n")
      .catch (error) ->
        displayErrors(error, msg)
    catch err
      msg.send "Unable to retrieve leaderboard."

  getResponseBody = (res) ->
    return res[0]

  displayErrors = (err, msg) ->
    robot.logger.error err
    for own key, error of err.data.errors
      msg.send error.message

  formatThousands = (num) ->
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
