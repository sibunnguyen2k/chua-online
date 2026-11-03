'use strict';

// CORS_ORIGINS: danh sách origin cách nhau bởi dấu phẩy, hoặc "*".
// Mặc định (dev): cho phép mọi cổng của localhost / 127.0.0.1.
const configured = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

const LOCAL_RE = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

function isAllowed(origin) {
  if (configured.length === 0) return LOCAL_RE.test(origin);
  return configured.includes('*') || configured.includes(origin);
}

function cors(req, res, next) {
  const origin = req.headers.origin;
  if (origin && isAllowed(origin)) {
    res.set('Access-Control-Allow-Origin', origin);
    res.set('Vary', 'Origin');
    res.set('Access-Control-Allow-Methods', 'GET,POST,PATCH,OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Authorization, Content-Type');
    res.set('Access-Control-Max-Age', '600');
  }
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  return next();
}

module.exports = { cors };
