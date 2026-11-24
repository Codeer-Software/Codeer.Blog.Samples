-- 設備一覧：今の設置場所は、設置中（ended_on が NULL）の設置履歴から出す
-- Database/equipment_list.sql の SELECT と同じ（末尾の ; だけ外している）
SELECT
  e.id               AS equipment_id,
  e.asset_no         AS asset_no,
  m.model_code       AS model_code,
  m.name             AS model_name,
  e.serial_no        AS serial_no,
  e.status           AS status,
  i.location         AS current_location,
  i.started_on       AS installed_on
FROM equipments e
JOIN device_models m ON m.id = e.device_model_id
LEFT JOIN installations i ON i.equipment_id = e.id AND i.ended_on IS NULL
ORDER BY e.asset_no
