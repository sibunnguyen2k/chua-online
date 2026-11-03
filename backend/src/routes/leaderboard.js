'use strict';

const express = require('express');
const { requireAuth } = require('../middleware/auth');
const service = require('../services/leaderboardService');
const { leaderboard: cfg } = require('../config');
const daily = require('../services/dailyService');

const router = express.Router();
router.use(requireAuth);

function parsePositiveInt(raw, fallback) {
  if (raw === undefined) return fallback;
  if (typeof raw !== 'string' || !/^\d+$/.test(raw)) return null;
  const n = Number(raw);
  return Number.isSafeInteger(n) && n > 0 ? n : null;
}

// GET /api/v1/leaderboard?page=1&limit=20
router.get('/leaderboard', async (req, res, next) => {
  try {
    const page = parsePositiveInt(req.query.page, 1);
    const limit = parsePositiveInt(req.query.limit, cfg.defaultLimit);
    if (page === null || limit === null || limit > cfg.maxLimit || page > 1e6) {
      return res.status(400).json({ error: 'invalid_pagination' });
    }
    const body = await service.getLeaderboardPage(page, limit, req.userId);
    res.set('Cache-Control', 'no-store');
    return res.json(body);
  } catch (err) {
    return next(err);
  }
});

// POST /api/v1/merit/sync  { "taps": 25 }
router.post('/merit/sync', async (req, res, next) => {
  try {
    const taps = req.body && req.body.taps;
    if (!Number.isSafeInteger(taps) || taps < 1 || taps > cfg.maxTapsPerSync) {
      return res.status(400).json({ error: 'invalid_taps' });
    }
    const totalMerit = await service.syncMerit(req.userId, taps);
    await daily.addProgress(req.userId, 'taps', taps);
    return res.json({ totalMerit });
  } catch (err) {
    return next(err);
  }
});

module.exports = router;
