'use strict';

const express = require('express');
const { requireAuth } = require('../middleware/auth');
const profile = require('../services/profileService');
const daily = require('../services/dailyService');
const devotion = require('../services/devotionService');

const publicRouter = express.Router();
const router = express.Router();

// Bọc async handler để lỗi chuyển thẳng tới error middleware.
const h = (fn) => (req, res, next) => Promise.resolve(fn(req, res)).then((r) => res.json(r)).catch(next);

// ---- Public ----
publicRouter.post('/auth/guest', h((req) => profile.createGuest(req.body && req.body.displayName)));

// ---- Authenticated ----
router.use(requireAuth);

router.get('/me', h((req) => profile.getMe(req.userId)));
router.patch('/me', h((req) => profile.updateMe(req.userId, req.body || {})));
router.post('/checkin', h((req) => profile.checkin(req.userId)));

router.get('/quests', h(async (req) => ({ items: await daily.getQuests(req.userId) })));
router.post('/quests/:id/claim', h((req) => daily.claimQuest(req.userId, req.params.id)));

router.get('/temples', h(async (req) => ({ items: await devotion.listTemples(req.query.q) })));

router.get('/offerings/catalog', h(async () => ({ items: devotion.offeringCatalog() })));
router.post('/offerings', h((req) => {
  const b = req.body || {};
  return devotion.makeOffering(req.userId, b.item, b.templeId);
}));

router.post('/chant', h((req) => devotion.chant(req.userId, (req.body || {}).count)));

router.get('/prayers', h((req) => devotion.listPrayers(req.userId, req.query.limit, req.query.before)));
router.post('/prayers', h((req) => devotion.createPrayer(req.userId, req.body || {})));

module.exports = { publicRouter, router };
