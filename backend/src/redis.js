'use strict';

const Redis = require('ioredis');
const config = require('./config');

const redis = new Redis(config.redisUrl, {
  maxRetriesPerRequest: 3,
  enableReadyCheck: true,
});

redis.on('error', (err) => console.error('[redis] error:', err.message));

module.exports = redis;
