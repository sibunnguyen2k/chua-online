'use strict';

const redis = require('../redis');
const config = require('../config');
const { unwrap } = require('../redisUtil');
const { HttpError } = require('../errors');
const { syncMerit } = require('./leaderboardService');

const DAY_TTL_SEC = 2 * 24 * 3600;

/** Ngày hiện tại theo múi giờ Việt Nam, dạng YYYY-MM-DD. */
function dayKey() {
  return new Date().toLocaleDateString('en-CA', { timeZone: config.timezone });
}

const dailyKey = (userId) => `daily:${userId}:${dayKey()}`;

/** Tăng bộ đếm tiến độ trong ngày; trả về giá trị mới. */
async function addProgress(userId, field, n) {
  const key = dailyKey(userId);
  const [value] = unwrap(
    await redis.multi().hincrby(key, field, n).expire(key, DAY_TTL_SEC).exec(),
  );
  return value;
}

/**
 * Tăng bộ đếm nhưng từ chối nếu vượt giới hạn/ngày (chống lạm dụng).
 * Hoàn tác khi vượt để bộ đếm luôn chính xác.
 */
async function addProgressCapped(userId, field, n, limit) {
  const value = await addProgress(userId, field, n);
  if (value > limit) {
    await redis.hincrby(dailyKey(userId), field, -n);
    throw new HttpError(429, 'daily_limit_reached');
  }
  return value;
}

async function getQuests(userId) {
  const h = await redis.hgetall(dailyKey(userId));
  return config.quests.map((q) => {
    const progress = Math.min(Number(h[q.metric] || 0), q.target);
    const claimed = h[`claimed:${q.id}`] === '1';
    return {
      id: q.id,
      title: q.title,
      target: q.target,
      reward: q.reward,
      progress,
      claimed,
      claimable: !claimed && progress >= q.target,
    };
  });
}

async function claimQuest(userId, questId) {
  const quest = config.quests.find((q) => q.id === questId);
  if (!quest) throw new HttpError(404, 'quest_not_found');

  const key = dailyKey(userId);
  const progress = Number((await redis.hget(key, quest.metric)) || 0);
  if (progress < quest.target) throw new HttpError(409, 'quest_not_completed');

  // HSETNX nguyên tử: chỉ một request được nhận thưởng.
  const first = await redis.hsetnx(key, `claimed:${quest.id}`, '1');
  if (!first) throw new HttpError(409, 'quest_already_claimed');

  const totalMerit = await syncMerit(userId, quest.reward);
  return { reward: quest.reward, totalMerit };
}

module.exports = { dayKey, addProgress, addProgressCapped, getQuests, claimQuest };
