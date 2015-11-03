# Hubot Fitbit Leaders [![npm version](https://badge.fury.io/js/hubot-fitbit-leaders.svg)](http://badge.fury.io/js/hubot-fitbit-leaders) [![Build Status](https://travis-ci.org/stephenyeargin/hubot-fitbit-leaders.png)](https://travis-ci.org/stephenyeargin/hubot-fitbit-leaders)

This script is designed to be used with a [Hubot](http://hubot.github.com) to compare the Fitbit activity of your friends.

## Adding to Your Hubot

See full instructions [here](https://github.com/github/hubot/blob/master/docs/scripting.md#npm-packages).

1. `npm install hubot-fitbit-leaders --save` (updates your `package.json` file)
2. Open the `external-scripts.json` file in the root directory (you may need to create this file) and add an entry to the array (e.g. `[ 'hubot-fitbit-leaders' ]`).

## Commands

- `hubot fitbit leaders` - Show table of leaders
- `hubot fitbit register` - Show how to friend the bot
- `hubot fitbit approve` - Approve all pending requests

## Suggested Setup

* Decide whether you want to use a user account or create a "robot" account to use with Fitbit
* Go to the [Fitbit Developer App Registration Page](https://dev.fitbit.com/apps/new) and create a new app using settings similar to these: ![Fitbit New App Form](http://i.imgur.com/JEnSON1.png)
* You should now see a screen similar to this one which you will need to keep open for the next step: ![Fitbit App Summary](http://i.imgur.com/H0Sf10E.png)
* Sign up for a free account with [Runscope](https://www.runscope.com) and once signed in visit their free [OAuth 1.0a Token Generator](https://www.runscope.com/oauth1_tool).
* Fill in the form with the consumer key and secret from the Fitbit Application you registered above like so: ![Runscope OAuth 1.0a Token Generator](http://i.imgur.com/ABOe4F5.png)
* Click Generate Token and you'll be redirected to a screen like this one: ![Runscope OAuth 1.0a Token Generator Success Page](http://i.imgur.com/vz3aJTz.png)
* The form fields presented there are, in order, the following Hubot environment variables:
 * `FITBIT_CLIENT_ID`
 * `FITBIT_CLIENT_SECRET`
 * `FITBIT_OAUTH_TOKEN`
 * `FITBIT_OAUTH_TOKEN_SECRET`
* Register the four values as environment variables when starting your bot (as usual with Hubot scripts) using `export` or `heroku config:set` or whatever applies to your Hubot hosting environment.
