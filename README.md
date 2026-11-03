# Chùa Online

Ứng dụng đi chùa online: thắp hương, gõ mõ, niệm Phật, tụng kinh, cầu nguyện, nhiệm vụ hằng ngày và bảng xếp hạng công đức toàn quốc (vô thời hạn).

- `backend/` — Node.js + Express, Redis (Sorted Set `leaderboard:global`), PostgreSQL.
- `flutter_app/` — ứng dụng Flutter.

## Chạy local

```bash
# Redis + PostgreSQL
docker run -d --name chua-redis -p 6379:6379 redis:7
docker run -d --name chua-pg -p 5432:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=chua_online postgres:16

# Back-end
cd backend && npm install
docker exec -i chua-pg psql -U postgres -d chua_online < sql/schema.sql
JWT_SECRET=dev-secret npm start

# Flutter (lần đầu: flutter create . để sinh android/ios/web)
cd flutter_app && flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

Biến môi trường back-end: `PORT`, `REDIS_URL`, `DATABASE_URL`, `JWT_SECRET`, `CORS_ORIGINS`, `SYNC_INTERVAL_MS`.
