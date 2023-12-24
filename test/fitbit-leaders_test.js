/* eslint-disable func-names */
/* global describe context beforeEach afterEach it */
const Helper = require('hubot-test-helper');
const chai = require('chai');
const nock = require('nock');

const {
  expect,
} = chai;

const helper = new Helper('../src/fitbit-leaders.js');

describe('hubot-fitbit-leaders', () => {
  beforeEach(() => {
    process.env.HUBOT_LOG_LEVEL = 'error';
    nock.disableNetConnect();
  });

  afterEach(() => {
    nock.cleanAll();
    delete process.env.HUBOT_LOG_LEVEL;
  });

  context('basic tests', () => {
    beforeEach(function () {
      process.env.HUBOT_LOG_LEVEL = 'error';
      process.env.FITBIT_CLIENT_ID = 'abc123';
      process.env.FITBIT_CLIENT_SECRET = '123abc456efg';
      process.env.FITBIT_OAUTH_TOKEN = 'hijk123abc456efg789lmnop';
      this.room = helper.createRoom();
    });

    afterEach(function () {
      this.room.destroy();
      delete process.env.HUBOT_LOG_LEVEL;
      delete process.env.FITBIT_CLIENT_ID;
      delete process.env.FITBIT_CLIENT_SECRET;
      delete process.env.FITBIT_OAUTH_TOKEN;
    });

    // hubot fitbit leaders
    it('returns the leaderboard of your friends', function (done) {
      nock('https://api.fitbit.com:443')
        .get('/1.1/user/-/leaderboard/friends.json')
        .replyWithFile(200, `${__dirname}/fixtures/leaderboard.json`);

      const selfRoom = this.room;
      selfRoom.user.say('alice', '@hubot fitbit leaders');
      setTimeout(
        () => {
          try {
            expect(selfRoom.messages).to.eql([
              ['alice', '@hubot fitbit leaders'],
              ['hubot', '\n#1 Stephen Y. - 15,220\n#2 Jason T. - 11,752'],
            ]);
            done();
          } catch (err) {
            done(err);
          }
        },
        1000,
      );
    });

    // hubot fitbit setup
    it('returns setup instructions', function (done) {
      const selfRoom = this.room;
      selfRoom.user.say('alice', '@hubot fitbit setup');
      setTimeout(
        () => {
          try {
            expect(selfRoom.messages).to.eql([
              ['alice', '@hubot fitbit setup'],
              ['hubot', "1) Go to: https://www.fitbit.com/oauth2/authorize?response_type=token&client_id=abc123&redirect_uri=http://localhost/&scope=profile%20social&expires_in=31536000\n2) Save the URL token in the bot's configuration as FITBIT_OAUTH_TOKEN\n3) Restart Hubot to load configuration"],
            ]);
            done();
          } catch (err) {
            done(err);
          }
        },
        1000,
      );
    });

    // hubot fitbit register
    it('returns registration instructions', function (done) {
      nock('https://api.fitbit.com:443')
        .get('/1/user/-/profile.json')
        .replyWithFile(200, `${__dirname}/fixtures/profile.json`);

      const selfRoom = this.room;
      selfRoom.user.say('alice', '@hubot fitbit register');
      setTimeout(
        () => {
          try {
            expect(selfRoom.messages).to.eql([
              ['alice', '@hubot fitbit register'],
              ['hubot', '1) Add Fitbit Bot as a friend - http://fitbit.com/user/257V3V\n2) Type `hubot fitbit approve`'],
            ]);
            done();
          } catch (err) {
            done(err);
          }
        },
        1000,
      );
    });

    // hubot fitbit friends
    it('returns a list of friends', function (done) {
      nock('https://api.fitbit.com:443')
        .get('/1.1/user/-/friends.json')
        .replyWithFile(200, `${__dirname}/fixtures/friends.json`);

      const selfRoom = this.room;
      selfRoom.user.say('alice', '@hubot fitbit friends');
      setTimeout(
        () => {
          try {
            expect(selfRoom.messages).to.eql([
              ['alice', '@hubot fitbit friends'],
              ['hubot', 'Stephen Y.'],
            ]);
            done();
          } catch (err) {
            done(err);
          }
        },
        1000,
      );
    });

    // hubot fitbit approve
    it('approves pending friend requests', function (done) {
      nock('https://api.fitbit.com:443')
        .get('/1.1/user/-/friends/invitations.json')
        .replyWithFile(200, `${__dirname}/fixtures/invitations.json`);
      nock('https://api.fitbit.com:443')
        .post('/1.1/user/-/friends/invitations/24M3J7')
        .query({
          accept: true,
        })
        .reply(201);

      const selfRoom = this.room;
      selfRoom.user.say('alice', '@hubot fitbit approve');
      setTimeout(
        () => {
          try {
            expect(selfRoom.messages).to.eql([
              ['alice', '@hubot fitbit approve'],
              ['hubot', 'Approved: Stephen Y.'],
            ]);
            done();
          } catch (err) {
            done(err);
          }
        },
        1000,
      );
    });
  });

  context('expired token', () => {
    beforeEach(function () {
      process.env.HUBOT_LOG_LEVEL = 'error';
      process.env.FITBIT_CLIENT_ID = 'abc123';
      process.env.FITBIT_CLIENT_SECRET = '123abc456efg';
      process.env.FITBIT_OAUTH_TOKEN = 'hijk123abc456efg789lmnop';
      this.room = helper.createRoom();
    });

    afterEach(function () {
      this.room.destroy();
      delete process.env.HUBOT_LOG_LEVEL;
      delete process.env.FITBIT_CLIENT_ID;
      delete process.env.FITBIT_CLIENT_SECRET;
      delete process.env.FITBIT_OAUTH_TOKEN;
    });

    // hubot fitbit leaders
    it('display an error for an expired token', function (done) {
      nock('https://api.fitbit.com:443')
        .get('/1.1/user/-/leaderboard/friends.json')
        .replyWithFile(401, `${__dirname}/fixtures/error-token-expired.json`);

      const selfRoom = this.room;
      selfRoom.user.say('alice', '@hubot fitbit leaders');
      setTimeout(
        () => {
          try {
            expect(selfRoom.messages).to.eql([
              ['alice', '@hubot fitbit leaders'],
              ['hubot', 'Your Fitbit token has expired! See `hubot fitbit token` to set up a new one.'],
            ]);
            done();
          } catch (err) {
            done(err);
          }
        },
        1000,
      );
    });
  });
});
