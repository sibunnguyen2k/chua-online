'use strict';

const crypto = require('crypto');
const db = require('../db');
const config = require('../config');
const { HttpError } = require('../errors');
const { syncMerit } = require('./leaderboardService');
const daily = require('./dailyService');

async function assertTemple(templeId) {
  if (templeId === undefined || templeId === null) return null;
  if (!Number.isSafeInteger(templeId) || templeId < 1) throw new HttpError(400, 'invalid_temple');
  const { rowCount } = await db.query('SELECT 1 FROM temples WHERE id = $1', [templeId]);
  if (rowCount === 0) throw new HttpError(404, 'temple_not_found');
  return templeId;
}

async function listTemples(q) {
  const term = typeof q === 'string' ? q.trim().slice(0, 60) : '';
  const { rows } = await db.query(
    `SELECT id, name, province, description, image_url
       FROM temples
      WHERE $1 = '' OR name ILIKE '%' || $1 || '%' OR province ILIKE '%' || $1 || '%'
      ORDER BY id LIMIT 100`,
    [term],
  );
  return rows.map((r) => ({
    id: r.id, name: r.name, province: r.province, description: r.description, imageUrl: r.image_url,
  }));
}

function offeringCatalog() {
  return Object.entries(config.offerings).map(([id, o]) => ({
    id, label: o.label, merit: o.merit, dailyLimit: o.dailyLimit,
  }));
}

/** Dâng lễ: thắp hương, hoa, đèn... mỗi vật phẩm có giới hạn/ngày. */
async function makeOffering(userId, item, templeId) {
  const spec = config.offerings[item];
  if (!spec) throw new HttpError(400, 'invalid_item');
  const temple = await assertTemple(templeId);

  await daily.addProgressCapped(userId, `off:${item}`, 1, spec.dailyLimit);
  if (item === 'incense') await daily.addProgress(userId, 'incense', 1);

  await db.query(
    'INSERT INTO offerings (user_id, temple_id, item, merit) VALUES ($1, $2, $3, $4)',
    [userId, temple, item, spec.merit],
  );
  const totalMerit = await syncMerit(userId, spec.merit);
  return { item, merit: spec.merit, totalMerit };
}

/** Niệm Phật: count biến (tối đa 1080/lần gọi), mỗi biến 1 công đức. */
async function chant(userId, count) {
  const c = config.chant;
  if (!Number.isSafeInteger(count) || count < 1 || count > c.maxPerCall) {
    throw new HttpError(400, 'invalid_count');
  }
  await daily.addProgressCapped(userId, 'chant', count, c.dailyLimit);
  const totalMerit = await syncMerit(userId, count);
  return { merit: count, totalMerit };
}

async function createPrayer(userId, { kind, content, templeId }) {
  const p = config.prayer;
  if (!p.kinds.includes(kind)) throw new HttpError(400, 'invalid_kind');
  const text = typeof content === 'string' ? content.trim() : '';
  if (text.length < 1 || text.length > 300) throw new HttpError(400, 'invalid_content');
  const temple = await assertTemple(templeId);

  await daily.addProgressCapped(userId, 'prayer', 1, p.dailyLimit);
  const id = crypto.randomUUID();
  const { rows } = await db.query(
    `INSERT INTO prayers (id, user_id, temple_id, kind, content)
     VALUES ($1, $2, $3, $4, $5) RETURNING created_at`,
    [id, userId, temple, kind, text],
  );
  const totalMerit = await syncMerit(userId, p.merit);
  return {
    prayer: { id, kind, content: text, templeId: temple, createdAt: rows[0].created_at },
    merit: p.merit,
    totalMerit,
  };
}

/** Lịch sử lời cầu nguyện của tôi, phân trang theo con trỏ thời gian (`before`). */
async function listPrayers(userId, limit, before) {
  const lim = Math.min(Math.max(Number(limit) || 20, 1), 50);
  let beforeTs = null;
  if (before !== undefined) {
    const d = new Date(before);
    if (Number.isNaN(d.getTime())) throw new HttpError(400, 'invalid_cursor');
    beforeTs = d.toISOString();
  }
  const { rows } = await db.query(
    `SELECT p.id, p.kind, p.content, p.temple_id, p.created_at, t.name AS temple_name
       FROM prayers p LEFT JOIN temples t ON t.id = p.temple_id
      WHERE p.user_id = $1 AND ($2::timestamptz IS NULL OR p.created_at < $2::timestamptz)
      ORDER BY p.created_at DESC LIMIT $3`,
    [userId, beforeTs, lim + 1],
  );
  const page = rows.slice(0, lim);
  return {
    items: page.map((r) => ({
      id: r.id, kind: r.kind, content: r.content,
      templeId: r.temple_id, templeName: r.temple_name, createdAt: r.created_at,
    })),
    nextCursor: rows.length > lim ? page[page.length - 1].created_at : null,
  };
}

module.exports = { listTemples, offeringCatalog, makeOffering, chant, createPrayer, listPrayers };
