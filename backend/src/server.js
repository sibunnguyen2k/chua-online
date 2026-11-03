'use strict';

const express = require('express');
const config = require('./config');
const redis = require('./redis');
const db = require('./db');
const { cors } = require('./middleware/cors');
const routes = require('./routes/leaderboard');
const appRoutes = require('./routes/app');
const { HttpError } = require('./errors');
const service = require('./services/leaderboardService');
const syncWorker = require('./workers/syncWorker');

async function main() {
  const loaded = await service.hydrateIfEmpty();
  if (loaded > 0) console.log(`[boot] rehydrated ${loaded} users into Redis`);

  const app = express();
  app.disable('x-powered-by');
  app.use(cors);
  app.use(express.json({ limit: '8kb' }));
  app.use('/api/v1', appRoutes.publicRouter);
  app.use('/api/v1', appRoutes.router);
  app.use('/api/v1', routes);

  // eslint-disable-next-line no-unused-vars
  app.use((err, _req, res, _next) => {
    if (err instanceof HttpError) return res.status(err.status).json({ error: err.code });
    console.error('[http] unhandled:', err);
    res.status(500).json({ error: 'internal_error' });
  });

  const server = app.listen(config.port, () => {
    console.log(`[http] listening on :${config.port}`);
  });
  syncWorker.start();

  let shuttingDown = false;
  const shutdown = async (signal) => {
    if (shuttingDown) return;
    shuttingDown = true;
    console.log(`[boot] ${signal} received, shutting down`);
    server.close();
    try {
      await syncWorker.stop(); // flush điểm chưa đồng bộ trước khi thoát
    } finally {
      await Promise.allSettled([redis.quit(), db.end()]);
      process.exit(0);
    }
  };
  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

main().catch((err) => {
  console.error('[boot] fatal:', err);
  process.exit(1);
});
