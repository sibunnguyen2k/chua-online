'use strict';

const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const redis = require('../redis');
const db = require('../db');
const config = require('../config');
const { unwrap } = require('../redisUtil');
const { HttpError } = require('../errors');
const { syncMerit } = require('./leaderboardService');
const daily = require('./dailyService');

function levelFor(merit) {
  const levels = config.levels;
  let idx = 0;
  for (let i = 0; i < levels.length; i++) if (merit >= levels[i].min) idx = i;
  const cur = levels[idx];
  const next = levels[idx + 1] || null;
  const progress = next ? (merit - cur.min) / (next.min - cur.min) : 1;
  return {
    index: idx,
    name: cur.name,
    nextName: next ? next.name : null,
    nextAt: next ? next.min : null,
    progress: Math.max(0, Math.min(1, progress)),
    all: levels.map((l) => ({ name: l.name, min: l.min })),
  };
}

function validateName(name) {
  if (typeof name !== 'string') throw new HttpError(400, 'invalid_name');
  const v = name.trim();
  if (v.length < 2 || v.length > 40) throw new HttpError(400, 'invalid_name');
  return v;
}

/** Tạo tài khoản khách và phát JWT (thay bằng đăng nhập thật khi có). */
async function createGuest(displayName) {
  const name = validateName(displayName);
  const id = crypto.randomUUID();
  await db.query('INSERT INTO users (id, display_name) VALUES ($1, $2)', [id, name]);
  const token = jwt.sign({ sub: id }, config.jwtSecret, { expiresIn: '365d' });
  return { token, userId: id };
}

async function getMe(userId) {
  const { rows } = await db.query(
    `SELECT id, display_name, avatar_url, total_merit, streak,
            to_char(last_checkin, 'YYYY-MM-DD') AS last_checkin
       FROM users WHERE id = $1`,
    [userId],
  );
  if (rows.length === 0) throw new HttpError(404, 'user_not_found');
  const u = rows[0];

  const [rank0, score] = unwrap(
    await redis
      .multi()
      .zrevrank(config.leaderboard.key, userId)
      .zscore(config.leaderboard.key, userId)
      .exec(),
  );
  const totalMerit = score !== null ? Number(score) : Number(u.total_merit);
  const today = daily.dayKey();
  const quests = await daily.getQuests(userId);

  return {
    id: u.id,
    name: u.display_name,
    avatarUrl: u.avatar_url,
    totalMerit,
    rank: rank0 !== null ? Number(rank0) + 1 : null,
    streak: u.streak,
    checkedInToday: u.last_checkin === today,
    claimableQuests: quests.filter((q) => q.claimable).length,
    level: levelFor(totalMerit),
  };
}

async function updateMe(userId, { displayName, avatarUrl }) {
  const name = displayName === undefined ? null : validateName(displayName);
  let avatar = null;
  if (avatarUrl !== undefined) {
    if (typeof avatarUrl !== 'string' || avatarUrl.length > 500 || !/^https:\/\//.test(avatarUrl)) {
      throw new HttpError(400, 'invalid_avatar');
    }
    avatar = avatarUrl;
  }
  await db.query(
    `UPDATE users SET display_name = COALESCE($2, display_name),
                      avatar_url   = COALESCE($3, avatar_url),
                      updated_at = now()
      WHERE id = $1`,
    [userId, name, avatar],
  );
  return getMe(userId);
}

/** Điểm danh: chuỗi ngày liên tiếp càng dài thưởng càng nhiều. Nguyên tử ở mức SQL. */
async function checkin(userId) {
  const today = daily.dayKey();
  const { rows } = await db.query(
    `UPDATE users
        SET streak = CASE WHEN last_checkin = $2::date - 1 THEN streak + 1 ELSE 1 END,
            last_checkin = $2::date
      WHERE id = $1 AND (last_checkin IS NULL OR last_checkin < $2::date)
  RETURNING streak`,
    [userId, today],
  );
  if (rows.length === 0) throw new HttpError(409, 'already_checked_in');

  const { base, perStreakDay, maxStreakBonusDays } = config.checkin;
  const streak = rows[0].streak;
  const reward = base + Math.min(streak, maxStreakBonusDays) * perStreakDay;
  const totalMerit = await syncMerit(userId, reward);
  return { streak, reward, totalMerit };
}

module.exports = { createGuest, getMe, updateMe, checkin, levelFor };
