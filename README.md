# Hubot Fitbit Leaders v2 [![npm version](https://badge.fury.io/js/hubot-fitbit-leaders.svg)](http://badge.fury.io/js/hubot-fitbit-leaders) [![Build Status](https://travis-ci.org/stephenyeargin/hubot-fitbit-leaders.png)](https://travis-ci.org/stephenyeargin/hubot-fitbit-leaders)

This script is designed to be used with a [Hubot](http://hubot.github.com) to compare the Fitbit activity of your friends.

## Adding to Your Hubot

See full instructions [here](https://github.com/github/hubot/blob/master/docs/scripting.md#npm-packages).

1. `npm install hubot-fitbit-leaders --save` (updates your `package.json` file)
2. Open the `external-scripts.json` file in the root directory (you may need to create this file) and add an entry to the array (e.g. `[ 'hubot-fitbit-leaders' ]`).

## Commands

- `hubot fitbit setup` - Run through the setup process for the bot (for admins)
- `hubot fitbit leaders` - Show table of leaders
- `hubot fitbit register` - Show how to friend the bot
- `hubot fitbit approve` - Approve all pending requests

## Upgrading from 1.0.x?

You will need to update your `FITBIT_CLIENT_ID` and generate a new `FITBIT_OAUTH_TOKEN` using the steps below. You no longer need the `FITBIT_OAUTH_TOKEN_SECRET` configuration variable. Note that you will have to go through this process at least once a year (the Implicit grant type token is time-limited.)

## Configuration

| Environment Variable   | Description                                     |
| -----------------------| ------------------------------------------------|
| `FITBIT_CLIENT_ID`     | Obtained from the app registration.             | 
| `FITBIT_CLIENT_SECRET` | Obtained from the app registration.             | 
| `FITBIT_OAUTH_TOKEN`   | Found in the callback response, lasts one year. | 

Register the three values as environment variables when starting your bot (as usual with Hubot scripts) using `export` or `heroku config:set` or whatever applies to your Hubot hosting environment.

## Suggested Setup

* Decide whether you want to use a user account or create a "robot" account to use with Fitbit
* Go to the [Fitbit Developer App Registration Page](https://dev.fitbit.com/apps/new) and register an application
 * The "Callback URL" field can be any running public web server. I prefer to use a [RunScope](https://runscope.com) bucket.
 * The "OAuth 2.0 Application Type: is "Client"
 * The application will need "Read & Write" access (for friend requests)
* Note the Client ID and Client Secret. Go ahead and add those to your configuration file and restart Hubot.
* Run the Fitbit setup command, e.g. `hubot fitbit setup`
* A URL will be displayed that contains your configured Client ID, but is missing the registered callback URL. Plug that in, then go through the authorization steps.
* Upon a successful authorization, the URL will appear in your browser containing your access token. It's very long, so make sure you grab everything between the `=` and the next `&`. Place these values into your configuration and restart Hubot.
* If all went well, type `hubot register` and see if you receive a response.

## Troubleshooting

- Remember that the token expires after a year, so be prepared to go through these steps at least that often (replacing the Access Token).
- Double check your saved configuration to make sure it matches the values displayed in the Fitbit application.
- The callback step is a bit tricky. The few times I've run it, I ended up with a server error, but was still able to retrieve the Access Token from the URL.
