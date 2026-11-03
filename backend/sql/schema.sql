CREATE TABLE IF NOT EXISTS users (
  id           UUID PRIMARY KEY,
  display_name TEXT        NOT NULL,
  avatar_url   TEXT,
  total_merit  BIGINT      NOT NULL DEFAULT 0 CHECK (total_merit >= 0),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Phục vụ rehydrate Redis theo keyset (id) chỉ với user có điểm.
CREATE INDEX IF NOT EXISTS idx_users_merit_positive
  ON users (id) WHERE total_merit > 0;

ALTER TABLE users ADD COLUMN IF NOT EXISTS streak       INT  NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS last_checkin DATE;

CREATE TABLE IF NOT EXISTS temples (
  id          SERIAL PRIMARY KEY,
  name        TEXT NOT NULL,
  province    TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  image_url   TEXT
);

CREATE TABLE IF NOT EXISTS prayers (
  id         UUID PRIMARY KEY,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  temple_id  INT REFERENCES temples(id),
  kind       TEXT NOT NULL CHECK (kind IN ('cau_an','cau_sieu','sam_hoi','cau_duyen','cau_tai')),
  content    TEXT NOT NULL CHECK (char_length(content) BETWEEN 1 AND 300),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_prayers_user_time ON prayers (user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS offerings (
  id         BIGSERIAL PRIMARY KEY,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  temple_id  INT REFERENCES temples(id),
  item       TEXT NOT NULL,
  merit      INT  NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_offerings_user_time ON offerings (user_id, created_at DESC);

INSERT INTO temples (name, province, description)
SELECT * FROM (VALUES
  ('Chùa Bái Đính', 'Ninh Bình', 'Quần thể chùa lớn nhất Việt Nam với nhiều kỷ lục về tượng Phật và chuông đồng.'),
  ('Chùa Yên Tử', 'Quảng Ninh', 'Thiền phái Trúc Lâm, nơi Phật hoàng Trần Nhân Tông tu hành.'),
  ('Chùa Một Cột', 'Hà Nội', 'Ngôi chùa có kiến trúc độc đáo hình bông sen giữa hồ.'),
  ('Chùa Thiên Mụ', 'Thừa Thiên Huế', 'Cổ tự bên bờ sông Hương, biểu tượng của cố đô Huế.'),
  ('Chùa Linh Ứng', 'Đà Nẵng', 'Chùa trên bán đảo Sơn Trà với tượng Quan Thế Âm cao 67m.'),
  ('Chùa Vĩnh Nghiêm', 'TP. Hồ Chí Minh', 'Ngôi chùa nổi tiếng với kho mộc bản kinh Phật.')
) AS t(name, province, description)
WHERE NOT EXISTS (SELECT 1 FROM temples);
