// Description:
//   Fitbit leaderboards
//
// Configuration:
//  FITBIT_CLIENT_ID
//  FITBIT_CLIENT_SECRET
//  FITBIT_OAUTH_TOKEN
//  FITBIT_REDIRECT_URL
//
// Commands:
//   hubot fitbit leaders - Show table of leaders
//   hubot fitbit register - Show how to friend the bot
//   hubot fitbit approve - Approve all pending requests
//
// Notes:
//   To obtain/set the FITBIT_OAUTH_TOKEN, you will need to visit the "Implicit"
//   authorization URL. This will grant you a non-refreshable token for a year.
//
// Authors:
//   stephenyeargin, hogepodge

const FitbitApiClient = require('fitbit-node');

module.exports = (robot) => {
  const getFitbitClient = (apiVersion) => new FitbitApiClient({
    clientId: process.env.FITBIT_CLIENT_ID,
    clientSecret: process.env.FITBIT_CLIENT_SECRET,
    apiVersion: apiVersion || '1.2',
  });
  const accessToken = process.env.FITBIT_OAUTH_TOKEN;
  const redirectUri = process.env.FITBIT_REDIRECT_URL || 'http://localhost/';

  const getResponseBody = (res) => res[0];

  const getResponseHeaders = (res) => res[1];

  const formatThousands = (num) => num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');

  const displayErrors = (err, msg) => {
    robot.logger.debug(err);
    Object.keys(err.errors || {}).forEach((key) => {
      const error = err.errors[key];
      if (error.errorType === 'expired_token') {
        msg.send(`Your Fitbit token has expired! See \`${robot.name} fitbit token\` to set up a new one.`);
      } else {
        robot.logger.error(err);
        msg.send(error.message);
      }
    });
  };

  const getLeaderboard = (msg) => {
    try {
      getFitbitClient('1.1').get('/leaderboard/friends.json', accessToken)
        .then((res) => {
          const responseBody = getResponseBody(res);
          const responseHeaders = getResponseHeaders(res);
          if (responseHeaders.statusCode !== 200) {
            displayErrors(responseBody, msg);
            return;
          }
          const leaders = responseBody.data;
          const relatedData = responseBody.included;
          const people = {};
          relatedData.forEach((person) => {
            people[person.id] = person;
          });
          const finalLeaders = [];
          Object.keys(leaders || {}).forEach((key) => {
            const leader = leaders[key];
            if (leader.attributes && (leader.attributes['step-summary'] > 0)) {
              const rank = leader.attributes['step-rank'];
              const displayName = people[leader.id].attributes.name || 'Unknown';
              const steps = formatThousands(leader.attributes['step-summary']) || 0;
              finalLeaders[rank] = `#${rank} ${displayName} - ${steps}`;
            }
          });
          msg.send(finalLeaders.join('\n'));
        }).catch((error) => displayErrors(error, msg));
    } catch (err) {
      msg.send('Unable to retrieve leaderboard.');
    }
  };

  // Default action
  robot.respond(/fitbit$/i, (msg) => getLeaderboard(msg));

  // Set up or renew the token
  robot.respond(/fitbit (?:token|setup)$/i, (msg) => {
    const url = ''
      + 'https://www.fitbit.com/oauth2/authorize?response_type=token'
      + `&client_id=${process.env.FITBIT_CLIENT_ID}`
      + `&redirect_uri=${redirectUri}`
      + '&scope=profile%20social&expires_in=31536000';
    msg.send(`\
1) Go to: ${url}
2) Save the URL token in the bot's configuration as FITBIT_OAUTH_TOKEN
3) Restart Hubot to load configuration\
`);
  });

  // Show the top five users
  robot.respond(/fitbit (steps|leaderboard|leaders)/i, (msg) => getLeaderboard(msg));

  // Who are my friends?
  robot.respond(/fitbit friends/i, (msg) => getFitbitClient('1.1').get('/friends.json', accessToken)
    .then((res) => {
      const responseBody = getResponseBody(res);
      const responseHeaders = getResponseHeaders(res);
      if (responseHeaders.statusCode !== 200) {
        displayErrors(responseBody, msg);
        return;
      }
      const friends = responseBody.data;
      if (friends.length > 0) {
        const list = [];
        Object.keys(friends || {}).forEach((key) => {
          const friend = friends[key];
          list.push(friend.attributes.name);
        });
        msg.send(list.join(', '));
        return;
      }
      msg.send('You have no friends on Fitbit. :(');
    }).catch((error) => displayErrors(error, msg)));

  // See how to friend the bot
  robot.respond(/fitbit register/i, (msg) => getFitbitClient('1').get('/profile.json', accessToken)
    .then((res) => {
      const responseBody = getResponseBody(res);
      const responseHeaders = getResponseHeaders(res);
      if (responseHeaders.statusCode !== 200) {
        displayErrors(responseBody, msg);
        return;
      }
      const {
        user,
      } = responseBody;
      if (!user.fullName) {
        user.fullName = 'the bot';
      }
      const userId = user.encodedId;
      msg.send(`\
1) Add ${user.fullName} as a friend - http://fitbit.com/user/${userId}
2) Type \`${robot.name} fitbit approve\`\
`);
    }).catch((error) => displayErrors(error, msg)));

  // Approve existing friend requests
  robot.respond(/fitbit approve/i, (msg) => getFitbitClient('1.1').get('/friends/invitations.json', accessToken)
    .then((res) => {
      const responseBody = getResponseBody(res);
      const responseHeaders = getResponseHeaders(res);
      if (responseHeaders.statusCode !== 200) {
        displayErrors(responseBody, msg);
        return;
      }
      if (responseBody.data.length === 0) {
        msg.send('No pending requests.');
        return;
      }

      const result = [];
      Object.keys(responseBody.included || {}).forEach((key) => {
        const friend = responseBody.included[key];
        result.push(getFitbitClient('1.1').post(
          `/friends/invitations/${friend.id}?accept=true`,
          accessToken,
        )
          .then((res2) => {
            robot.logger.debug(getResponseBody(res2));
            msg.send(`Approved: ${friend.attributes.name}`);
          }).catch((error) => displayErrors(error, msg)));
      });
    }).catch((error) => displayErrors(error, msg)));
};
