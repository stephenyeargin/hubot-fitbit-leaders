/* global describe context beforeEach afterEach it */
const chai = require('chai');
const nock = require('nock');

const {
  expect,
} = chai;

const loadScript = require('../src/fitbit-leaders.js');

const createHarness = () => {
  const handlers = [];
  const messages = [];
  const robot = {
    name: 'hubot',
    logger: {
      debug: () => {},
      error: () => {},
    },
    respond: (pattern, callback) => {
      handlers.push({
        pattern,
        callback,
      });
    },
  };

  loadScript(robot);

  const send = (user, text) => {
    messages.push([user, text]);
    const commandText = text.replace(/^@hubot\s+/i, '');
    const match = handlers.find((handler) => handler.pattern.test(commandText));
    if (!match) {
      return;
    }

    match.callback({
      send: (response) => messages.push(['hubot', response]),
    });
  };

  return {
    messages,
    send,
  };
};

const waitForResponse = () => new Promise((resolve) => {
  setTimeout(resolve, 100);
});

describe('hubot-fitbit-leaders', () => {
  beforeEach(() => {
    process.env.HUBOT_LOG_LEVEL = 'error';
    process.env.HUBOT_NAME = 'hubot';
    nock.disableNetConnect();
  });

  afterEach(() => {
    nock.cleanAll();
    delete process.env.HUBOT_LOG_LEVEL;
    delete process.env.HUBOT_NAME;
  });

  context('basic tests', () => {
    beforeEach(function () {
      process.env.HUBOT_LOG_LEVEL = 'error';
      process.env.FITBIT_CLIENT_ID = 'abc123';
      process.env.FITBIT_CLIENT_SECRET = '123abc456efg';
      process.env.FITBIT_OAUTH_TOKEN = 'hijk123abc456efg789lmnop';
      this.harness = createHarness();
    });

    afterEach(function () {
      delete process.env.HUBOT_LOG_LEVEL;
      delete process.env.FITBIT_CLIENT_ID;
      delete process.env.FITBIT_CLIENT_SECRET;
      delete process.env.FITBIT_OAUTH_TOKEN;
    });

    // hubot fitbit leaders
    it('returns the leaderboard of your friends', async function () {
      nock('https://api.fitbit.com:443')
        .get('/1.1/user/-/leaderboard/friends.json')
        .replyWithFile(200, `${__dirname}/fixtures/leaderboard.json`);

      this.harness.send('alice', '@hubot fitbit leaders');
      await waitForResponse();

      expect(this.harness.messages).to.eql([
        ['alice', '@hubot fitbit leaders'],
        ['hubot', '\n#1 Stephen Y. - 15,220\n#2 Jason T. - 11,752'],
      ]);
    });

    // hubot fitbit setup
    it('returns setup instructions', async function () {
      this.harness.send('alice', '@hubot fitbit setup');
      await waitForResponse();

      expect(this.harness.messages).to.eql([
        ['alice', '@hubot fitbit setup'],
        ['hubot', "1) Go to: https://www.fitbit.com/oauth2/authorize?response_type=token&client_id=abc123&redirect_uri=http://localhost/&scope=profile%20social&expires_in=31536000\n2) Save the URL token in the bot's configuration as FITBIT_OAUTH_TOKEN\n3) Restart Hubot to load configuration"],
      ]);
    });

    // hubot fitbit register
    it('returns registration instructions', async function () {
      nock('https://api.fitbit.com:443')
        .get('/1/user/-/profile.json')
        .replyWithFile(200, `${__dirname}/fixtures/profile.json`);

      this.harness.send('alice', '@hubot fitbit register');
      await waitForResponse();

      expect(this.harness.messages).to.eql([
        ['alice', '@hubot fitbit register'],
        ['hubot', '1) Add Fitbit Bot as a friend - http://fitbit.com/user/257V3V\n2) Type `hubot fitbit approve`'],
      ]);
    });

    // hubot fitbit friends
    it('returns a list of friends', async function () {
      nock('https://api.fitbit.com:443')
        .get('/1.1/user/-/friends.json')
        .replyWithFile(200, `${__dirname}/fixtures/friends.json`);

      this.harness.send('alice', '@hubot fitbit friends');
      await waitForResponse();

      expect(this.harness.messages).to.eql([
        ['alice', '@hubot fitbit friends'],
        ['hubot', 'Stephen Y.'],
      ]);
    });

    // hubot fitbit approve
    it('approves pending friend requests', async function () {
      nock('https://api.fitbit.com:443')
        .get('/1.1/user/-/friends/invitations.json')
        .replyWithFile(200, `${__dirname}/fixtures/invitations.json`);
      nock('https://api.fitbit.com:443')
        .post('/1.1/user/-/friends/invitations/24M3J7')
        .query({
          accept: true,
        })
        .reply(201);

      this.harness.send('alice', '@hubot fitbit approve');
      await waitForResponse();

      expect(this.harness.messages).to.eql([
        ['alice', '@hubot fitbit approve'],
        ['hubot', 'Approved: Stephen Y.'],
      ]);
    });
  });

  context('expired token', () => {
    beforeEach(function () {
      process.env.HUBOT_LOG_LEVEL = 'error';
      process.env.FITBIT_CLIENT_ID = 'abc123';
      process.env.FITBIT_CLIENT_SECRET = '123abc456efg';
      process.env.FITBIT_OAUTH_TOKEN = 'hijk123abc456efg789lmnop';
      this.harness = createHarness();
    });

    afterEach(function () {
      delete process.env.HUBOT_LOG_LEVEL;
      delete process.env.FITBIT_CLIENT_ID;
      delete process.env.FITBIT_CLIENT_SECRET;
      delete process.env.FITBIT_OAUTH_TOKEN;
    });

    // hubot fitbit leaders
    it('display an error for an expired token', async function () {
      nock('https://api.fitbit.com:443')
        .get('/1.1/user/-/leaderboard/friends.json')
        .replyWithFile(401, `${__dirname}/fixtures/error-token-expired.json`);

      this.harness.send('alice', '@hubot fitbit leaders');
      await waitForResponse();

      expect(this.harness.messages).to.eql([
        ['alice', '@hubot fitbit leaders'],
        ['hubot', 'Your Fitbit token has expired! See `hubot fitbit token` to set up a new one.'],
      ]);
    });
  });
});
