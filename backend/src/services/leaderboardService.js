'use strict';

const redis = require('../redis');
const db = require('../db');
const { unwrap } = require('../redisUtil');
const { leaderboard: cfg } = require('../config');

/**
 * sync_merit: cộng dồn `taps` vào điểm vĩnh viễn của user.
 * ZINCRBY + SADD(dirty) trong cùng một MULTI => worker luôn biết user nào đã đổi.
 * @returns {Promise<number>} tổng điểm mới
 */
async function syncMerit(userId, taps) {
  const [newScore] = unwrap(
    await redis
      .multi()
      .zincrby(cfg.key, taps, userId) // ZINCRBY leaderboard:global <taps> <userId>
      .sadd(cfg.dirtyKey, userId)
      .exec(),
  );
  return Number(newScore);
}

/** Lấy hồ sơ hiển thị của nhiều user bằng một truy vấn duy nhất. */
async function loadProfiles(ids) {
  if (ids.length === 0) return new Map();
  const { rows } = await db.query(
    'SELECT id, display_name, avatar_url FROM users WHERE id = ANY($1::uuid[])',
    [ids],
  );
  return new Map(rows.map((r) => [r.id, r]));
}

/**
 * Trang bảng xếp hạng + thứ hạng của user đang xem.
 * 4 lệnh Redis gói trong 1 round-trip: ZREVRANGE, ZCARD, ZREVRANK, ZSCORE.
 */
async function getLeaderboardPage(page, limit, currentUserId) {
  const start = (page - 1) * limit;
  const end = start + limit - 1;

  const [flat, total, myRank0, myScore] = unwrap(
    await redis
      .multi()
      .zrevrange(cfg.key, start, end, 'WITHSCORES')
      .zcard(cfg.key)
      .zrevrank(cfg.key, currentUserId)
      .zscore(cfg.key, currentUserId)
      .exec(),
  );

  const entries = [];
  for (let i = 0; i < flat.length; i += 2) {
    entries.push({ userId: flat[i], score: Number(flat[i + 1]) });
  }

  const lookupIds = entries.map((e) => e.userId);
  const meOnBoard = myRank0 !== null && myScore !== null;
  if (meOnBoard) lookupIds.push(currentUserId);
  const profiles = await loadProfiles([...new Set(lookupIds)]);

  const toItem = (e, rank) => {
    const p = profiles.get(e.userId);
    return {
      rank,
      userId: e.userId,
      name: p ? p.display_name : 'Phật tử ẩn danh',
      avatarUrl: p ? p.avatar_url : null,
      score: e.score,
    };
  };

  const items = entries.map((e, i) => toItem(e, start + i + 1));
  const me = meOnBoard
    ? toItem({ userId: currentUserId, score: Number(myScore) }, Number(myRank0) + 1)
    : null;

  return { page, limit, total, hasMore: end + 1 < total, items, me };
}

/**
 * Khôi phục Redis từ PostgreSQL khi key bị mất (Redis restart không persistence).
 * ZADD NX: chỉ thêm member chưa tồn tại, không ghi đè điểm mới hơn trong Redis.
 */
async function hydrateIfEmpty(batchSize = 5000) {
  if (await redis.exists(cfg.key)) return 0;

  let lastId = '00000000-0000-0000-0000-000000000000';
  let loaded = 0;
  for (;;) {
    const { rows } = await db.query(
      `SELECT id, total_merit FROM users
       WHERE total_merit > 0 AND id > $1::uuid
       ORDER BY id LIMIT $2`,
      [lastId, batchSize],
    );
    if (rows.length === 0) break;

    const args = [];
    for (const r of rows) args.push(Number(r.total_merit), r.id);
    await redis.zadd(cfg.key, 'NX', ...args);

    loaded += rows.length;
    lastId = rows[rows.length - 1].id;
  }
  return loaded;
}

module.exports = { syncMerit, getLeaderboardPage, hydrateIfEmpty };
