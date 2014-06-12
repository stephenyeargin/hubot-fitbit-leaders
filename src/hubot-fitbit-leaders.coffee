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
#  FITBIT_OAUTH_TOKEN_SECRET
#
# Commands:
#   hubot fitbit leaders - Show table of leaders
#   hubot fitbit register - Show how to friend the bot
#   hubot fitbit approve - Approve pending requests
#
# Notes:
#   To obtain/set the FITBIT_OAUTH_TOKEN / FITBIT_OAUTH_TOKEN_SECRET, you will need to go through the OAuth handshake manually with your bot's credentials
#
# Authors:
#   stephenyeargin, hogepodge

Util = require "util"

module.exports = (robot) ->

  config = secrets:
    clientId: process.env.FITBIT_CLIENT_ID
    clientSecret: process.env.FITBIT_CLIENT_SECRET
    oauthToken: process.env.FITBIT_OAUTH_TOKEN
    oauthTokenSecret: process.env.FITBIT_OAUTH_TOKEN_SECRET

  fitbit = require("fitbit-js")(config.secrets.clientId, config.secrets.clientSecret)


  # Default action
  robot.respond /fitbit$/i, (msg) ->

    getLeaderboard(msg)

  # Show the top five users
  robot.respond /fitbit (steps|leaderboard|leaders)/i, (msg) ->

    getLeaderboard(msg)

  # Who are my friends?
  robot.respond /fitbit friends/i, (msg) ->

    params =
      token:
        oauth_token: config.secrets.oauthToken
        oauth_token_secret: config.secrets.oauthTokenSecret

    fitbit.apiCall 'GET', '/user/-/friends.json', params, (err, response, json) ->

      if err?
        displayErrors err, msg
        return

      friends = json.friends

      if friends.length > 0

        list = []
        for own key, friend of friends
          list.push "#{friend.user.displayName}"

        msg.send list.join(", ")

      else
        msg.send "You have no friends on Fitbit. :("

  # See how to friend the bot
  robot.respond /fitbit register/i, (msg) ->

    params =
      token:
        oauth_token: config.secrets.oauthToken
        oauth_token_secret: config.secrets.oauthTokenSecret

    fitbit.apiCall 'GET', '/user/-/profile.json', params, (err, response, json) ->

      if err?
        displayErrors err, msg
        return

      user = json.user
      unless user.fullName
        user.fullName = 'the bot'

      msg.send "Friend #{user.fullName} at http://fitbit.com/user/#{user.encodedId}"

  # Approve existing friend requests
  robot.respond /fitbit approve/i, (msg) ->

    params =
      token:
        oauth_token: config.secrets.oauthToken
        oauth_token_secret: config.secrets.oauthTokenSecret

    fitbit.apiCall 'GET', '/user/-/friends/invitations.json', params, (err, response, json) ->

      requests = json.friends

      if json.friends.length is 0
        msg.send "No pending requests."
        return

      for own key, friend of requests

        params =
          token:
            oauth_token: config.secrets.oauthToken
            oauth_token_secret: config.secrets.oauthTokenSecret
          accept: true

        fitbit.apiCall 'POST', "/user/-/friends/invitations/#{friend.user.encodedId}.json", params, (err, response, json) ->

          if err?
            displayErrors err, msg
            return

          msg.send "Approve: #{friend.user.displayName}"

  getLeaderboard = (msg) ->
    try
      params =
        token:
          oauth_token: config.secrets.oauthToken
          oauth_token_secret: config.secrets.oauthTokenSecret

      fitbit.apiCall 'GET', '/user/-/friends/leaderboard.json', params, (err, response, json) ->

        if err?
          displayErrors err, msg
          return

        leaders = json.friends
        sortedleaders = []

        for own key, leader of leaders
          if leader.summary.steps > 0
            rank = leader.rank.steps * 1 # force conversion to a number
            sortedleaders[rank] = "##{leader.rank.steps} #{leader.user.displayName} - #{formatThousands(leader.summary.steps)}"

        msg.send sortedleaders.join("\n")

    catch err
      msg.send "Unable to retrieve leaderboard."

  displayErrors = (err, msg) ->

    for own key, error of err.data.errors
      msg.send error.message

  formatThousands = (num) ->
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",")
