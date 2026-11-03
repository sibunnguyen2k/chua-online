'use strict';

const env = process.env;

const int = (value, fallback) => {
  const n = Number.parseInt(value, 10);
  return Number.isFinite(n) ? n : fallback;
};

module.exports = Object.freeze({
  port: int(env.PORT, 3000),
  redisUrl: env.REDIS_URL || 'redis://127.0.0.1:6379',
  databaseUrl: env.DATABASE_URL || 'postgres://postgres:postgres@127.0.0.1:5432/chua_online',
  jwtSecret: env.JWT_SECRET || 'change-me',
  timezone: 'Asia/Ho_Chi_Minh', // ranh giới "ngày mới" cho nhiệm vụ & điểm danh

  leaderboard: Object.freeze({
    key: 'leaderboard:global',        // ZSET vô thời hạn, không bao giờ reset
    dirtyKey: 'leaderboard:dirty',    // SET các userId có điểm thay đổi
    processingKey: 'leaderboard:dirty:processing',
    lockKey: 'leaderboard:sync:lock',
    defaultLimit: 20,
    maxLimit: 50,
    maxTapsPerSync: 10000,
  }),

  worker: Object.freeze({
    intervalMs: int(env.SYNC_INTERVAL_MS, 5 * 60 * 1000), // 5 phút
    batchSize: int(env.SYNC_BATCH_SIZE, 1000),
    lockTtlSec: int(env.SYNC_LOCK_TTL_SEC, 240),
  }),

  // Phẩm vị theo tổng công đức (tăng dần).
  levels: Object.freeze([
    { name: 'Sơ Tâm', min: 0 },
    { name: 'Tinh Tấn', min: 1000 },
    { name: 'Thiện Tín', min: 5000 },
    { name: 'Hộ Pháp', min: 20000 },
    { name: 'Bồ Đề Tâm', min: 100000 },
    { name: 'Đại Thí Chủ', min: 500000 },
  ]),

  // Vật phẩm dâng lễ: công đức mỗi lần và giới hạn mỗi ngày.
  offerings: Object.freeze({
    incense: { label: 'Thắp hương', merit: 5, dailyLimit: 10 },
    flower: { label: 'Dâng hoa', merit: 8, dailyLimit: 10 },
    lamp: { label: 'Thắp đèn', merit: 10, dailyLimit: 10 },
    fruit: { label: 'Dâng trái cây', merit: 12, dailyLimit: 5 },
    meal: { label: 'Dâng cơm chay', merit: 20, dailyLimit: 3 },
  }),

  prayer: Object.freeze({ merit: 10, dailyLimit: 20, kinds: ['cau_an', 'cau_sieu', 'sam_hoi', 'cau_duyen', 'cau_tai'] }),
  chant: Object.freeze({ maxPerCall: 1080, dailyLimit: 10800 }),

  // metric khớp field trong hash daily:<userId>:<yyyy-mm-dd>
  quests: Object.freeze([
    { id: 'tap_100', metric: 'taps', title: 'Gõ mõ 100 lần', target: 100, reward: 20 },
    { id: 'incense_1', metric: 'incense', title: 'Thắp một nén hương', target: 1, reward: 10 },
    { id: 'prayer_1', metric: 'prayer', title: 'Gửi một lời cầu nguyện', target: 1, reward: 15 },
    { id: 'chant_108', metric: 'chant', title: 'Niệm Phật 108 biến', target: 108, reward: 30 },
  ]),

  checkin: Object.freeze({ base: 10, perStreakDay: 5, maxStreakBonusDays: 7 }),
});
