'use strict';

const crypto = require('crypto');
const redis = require('../redis');
const db = require('../db');
const config = require('../config');

const { leaderboard: lb, worker: wk } = config;

const RELEASE_LOCK_LUA = `
if redis.call('get', KEYS[1]) == ARGV[1] then
  return redis.call('del', KEYS[1])
end
return 0`;

/**
 * Bulk update một lô user. Ghi GIÁ TRỊ TUYỆT ĐỐI từ Redis => idempotent,
 * chạy lại bao nhiêu lần cũng đúng. Dùng UPDATE ... FROM unnest vì hàng users
 * luôn tồn tại (đã tạo khi đăng ký; display_name NOT NULL nên không thể
 * INSERT ... ON CONFLICT thiếu cột). IS DISTINCT FROM bỏ qua ghi thừa.
 */
async function bulkUpdateMerit(ids, scores) {
  const { rowCount } = await db.query(
    `UPDATE users AS u
        SET total_merit = v.score, updated_at = now()
       FROM unnest($1::uuid[], $2::bigint[]) AS v(id, score)
      WHERE u.id = v.id AND u.total_merit IS DISTINCT FROM v.score`,
    [ids, scores],
  );
  return rowCount;
}

async function flushBatch(userIds) {
  const unique = [...new Set(userIds)];
  const pipeline = redis.pipeline();
  for (const id of unique) pipeline.zscore(lb.key, id);
  const results = await pipeline.exec();

  const ids = [];
  const scores = [];
  results.forEach(([err, score], i) => {
    if (err) throw err;
    if (score === null) return; // user đã bị xoá khỏi ZSET
    ids.push(unique[i]);
    scores.push(Math.round(Number(score)));
  });
  if (ids.length === 0) return 0;
  return bulkUpdateMerit(ids, scores);
}

/**
 * Một chu kỳ đồng bộ.
 * - Khoá phân tán (SET NX EX) để nhiều instance không chạy trùng.
 * - RENAME dirty -> processing là nguyên tử: ZINCRBY mới trong lúc đồng bộ
 *   sẽ rơi vào set dirty mới, không bị mất.
 * - Nếu chu kỳ trước lỗi giữa chừng, set processing còn đó và được xử lý lại.
 */
async function runOnce() {
  const token = crypto.randomUUID();
  const locked = await redis.set(lb.lockKey, token, 'EX', wk.lockTtlSec, 'NX');
  if (!locked) return { skipped: true, updated: 0 };

  let updated = 0;
  try {
    if (!(await redis.exists(lb.processingKey))) {
      try {
        await redis.rename(lb.dirtyKey, lb.processingKey);
      } catch (err) {
        if (/no such key/i.test(err.message)) return { skipped: false, updated: 0 };
        throw err;
      }
    }

    let cursor = '0';
    do {
      const [next, ids] = await redis.sscan(lb.processingKey, cursor, 'COUNT', wk.batchSize);
      cursor = next;
      if (ids.length > 0) updated += await flushBatch(ids);
    } while (cursor !== '0');

    await redis.del(lb.processingKey); // chỉ xoá khi toàn bộ đã ghi DB thành công
    return { skipped: false, updated };
  } finally {
    await redis.eval(RELEASE_LOCK_LUA, 1, lb.lockKey, token).catch(() => {});
  }
}

let timer = null;
let running = false;

async function tick() {
  if (running) return; // chống chồng chéo nếu một chu kỳ kéo dài > interval
  running = true;
  try {
    const r = await runOnce();
    if (!r.skipped) console.log(`[sync-worker] updated ${r.updated} users`);
  } catch (err) {
    console.error('[sync-worker] failed, will retry next tick:', err.message);
  } finally {
    running = false;
  }
}

function start() {
  if (timer) return;
  timer = setInterval(tick, wk.intervalMs);
  console.log(`[sync-worker] started, every ${wk.intervalMs / 1000}s`);
}

/** Dừng timer và flush lần cuối (dùng khi graceful shutdown). */
async function stop() {
  if (timer) clearInterval(timer);
  timer = null;
  await tick();
}

module.exports = { start, stop, runOnce };
