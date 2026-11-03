'use strict';

const jwt = require('jsonwebtoken');
const config = require('../config');

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/** Xác thực Bearer JWT; userId nằm trong claim `sub`. Gán req.userId. */
function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'missing_token' });
  }
  try {
    const payload = jwt.verify(token, config.jwtSecret);
    if (typeof payload.sub !== 'string' || !UUID_RE.test(payload.sub)) {
      return res.status(401).json({ error: 'invalid_token' });
    }
    req.userId = payload.sub.toLowerCase();
    return next();
  } catch (_) {
    return res.status(401).json({ error: 'invalid_token' });
  }
}

module.exports = { requireAuth };
