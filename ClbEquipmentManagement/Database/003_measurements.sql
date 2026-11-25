-- ClbEquipmentManagement：計測値のテーブル（NAK-06）
-- 対象：SQLite。データソース Main（main.db）に作る。002_seed.sql のあとに流す。
-- 計測値は機器（NAK-06 ではシミュレーター）から受信API で受け取る。架空データの行は入れない。

-- 計測値：1回の送信で1行
-- measured_at は UTC で持つ。受信API が時差付きの時刻を UTC に直してから保存し、
-- 画面では DateTimeField の「UTCとして保存」で現地時刻に直して表示する。
-- この列に日本時間を入れない（入れると、画面で9時間ずれる）。
CREATE TABLE measurements (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  equipment_id  INTEGER NOT NULL REFERENCES equipments(id),
  measured_at   DATETIME NOT NULL,  -- 機器が付けた計測時刻（UTC）
  metric        TEXT NOT NULL,      -- 計測項目：temperature（温度）・flow（流量）
  value         REAL NOT NULL,      -- 値。範囲は検証しない（異常値の扱いは NAK-12）
  unit          TEXT NOT NULL       -- 単位：℃・L/min
);

-- 設備ごとに、計測時刻の順で読むための索引
CREATE INDEX ix_measurements_equipment_time
  ON measurements(equipment_id, measured_at);
