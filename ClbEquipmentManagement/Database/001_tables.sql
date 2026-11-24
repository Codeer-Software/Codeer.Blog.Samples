-- ClbEquipmentManagement：設備台帳のテーブル（NAK-04）
-- 対象：SQLite。データソース Main（main.db）に作る。000_base.sql のあとに流す。

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
-- 日付の列は TEXT ではなく DATE で宣言する（CLB の資料「SQLite 日付/時刻列は TEXT で宣言しない」に従う）。
-- SQLite には日付の型がなく、値は文字列で保存される。CLB は DateField の値（日付だけ）を
-- 0 時の日時に変えて書くので、DB には 2023-01-01 00:00:00 の形で入る（CLB 開発チームに確認、2026-11-24）。
-- CLB は検索の条件も同じ形で渡すので、この形のまま持つ。
CREATE TABLE installations (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  equipment_id  INTEGER NOT NULL REFERENCES equipments(id),
  location      TEXT NOT NULL,   -- 設置場所
  started_on    DATE NOT NULL,   -- 開始日（日付だけを持つ。YYYY-MM-DD 00:00:00）
  ended_on      DATE,            -- 終了日（同上。設置中は NULL）
  reason        TEXT NOT NULL,   -- 新設・移設・交換・撤去
  note          TEXT,
  -- 時刻は持たない：日付として読めて、時刻が 0 時の値だけを受け付ける
  CHECK (date(started_on) IS NOT NULL AND started_on = date(started_on) || ' 00:00:00'),
  CHECK (ended_on IS NULL OR (date(ended_on) IS NOT NULL AND ended_on = date(ended_on) || ' 00:00:00'))
);

-- 1台の設備に、設置中（終了日が NULL）の行は1つだけ
CREATE UNIQUE INDEX ux_installations_open
  ON installations(equipment_id) WHERE ended_on IS NULL;
