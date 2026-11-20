-- ClbEquipmentManagement：設備台帳のテーブル（NAK-04）
-- 対象：SQLite。データソース Main（main.db）に作る。

-- 機種：型番ごとに共通の仕様を持つ
CREATE TABLE device_models (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  model_code  TEXT NOT NULL UNIQUE,   -- 型番
  name        TEXT NOT NULL,          -- 機種名
  category    TEXT NOT NULL,          -- 種類（恒温槽、ポンプなど）
  spec        TEXT                    -- 機種共通の仕様
);

-- 設備（個体）：1台ごとの記録。今の設置場所は持たない（設置履歴から出す）
CREATE TABLE equipments (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  asset_no         TEXT NOT NULL UNIQUE,  -- 管理番号（社内で付ける）
  device_model_id  INTEGER NOT NULL REFERENCES device_models(id),
  serial_no        TEXT NOT NULL,         -- 製造番号（メーカーが付ける）
  status           TEXT NOT NULL,         -- 稼働中・保管中・修理中・廃棄
  note             TEXT,
  UNIQUE (device_model_id, serial_no)
);

-- 設置履歴：場所は上書きせず、行を足していく
CREATE TABLE installations (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  equipment_id  INTEGER NOT NULL REFERENCES equipments(id),
  location      TEXT NOT NULL,   -- 設置場所
  started_on    TEXT NOT NULL,   -- 開始日（YYYY-MM-DD）
  ended_on      TEXT,            -- 終了日（設置中は NULL）
  reason        TEXT NOT NULL,   -- 新設・移設・交換・撤去
  note          TEXT
);

-- 1台の設備に、設置中（終了日が NULL）の行は1つだけ
CREATE UNIQUE INDEX ux_installations_open
  ON installations(equipment_id) WHERE ended_on IS NULL;
