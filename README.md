# Hubot Fitbit Leaders

This script is designed to be used with a [Hubot](http://hubot.github.com) to compare the Fitbit activity of your friends.

## Suggested Setup

* Decide whether you want to use a user account or create a "robot" account to use with Fitbit
* Register a new Fitbit application with whichever you selected in the previous step
* Using the supplied OAuth credentials from registration, obtain a `FITBIT_OAUTH_TOKEN` and `FITBIT_OAUTH_TOKEN_SECRET` by manually walking through the OAuth process (use a tool like [Runscope](https://www.runscope.com/) to make this a bit easier).
* Register the returned values as environment variables when starting your bot (as usual with Hubot scripts).

## Commands

- `hubot fitbit leaders` - Show table of leaders
- `hubot fitbit register` - Show how to friend the bot
- `hubot fitbit approve` - Approve pending requests