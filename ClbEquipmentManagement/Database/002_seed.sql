-- ClbEquipmentManagement：架空データ（NAK-04の初期状態）
-- 型番・製造番号・場所はすべて架空。実在の製品と重ならないよう型番に EX- を付けている。

INSERT INTO device_models (id, model_code, name, category, spec) VALUES
  (1, 'EX-TC100', '小型恒温槽', '恒温槽', '設定範囲 -20〜80℃'),
  (2, 'EX-TC200', '中型恒温槽', '恒温槽', '設定範囲 -40〜150℃'),
  (3, 'EX-PU050', '循環ポンプ', 'ポンプ', '最大流量 50 L/min');

INSERT INTO equipments (id, asset_no, device_model_id, serial_no, status) VALUES
  (1, 'EQ-0001', 1, 'TC100-0001', '稼働中'),
  (2, 'EQ-0002', 1, 'TC100-0002', '稼働中'),
  (3, 'EQ-0003', 3, 'PU050-0001', '稼働中'),
  (4, 'EQ-0004', 2, 'TC200-0001', '稼働中'),
  (5, 'EQ-0005', 1, 'TC100-0003', '保管中');

-- 交換（シナリオC）と移設（シナリオD）は、ここでは入れず画面から操作する
INSERT INTO installations (id, equipment_id, location, started_on, ended_on, reason) VALUES
  (1, 1, '第1棟 試験室A',   '2024-04-01', NULL, '新設'),
  (2, 2, '第1棟 試験室B',   '2024-04-01', NULL, '新設'),
  (3, 3, '第2棟 冷却設備',  '2024-04-01', NULL, '新設'),
  (4, 4, '第2棟 評価室',    '2025-07-01', NULL, '新設'),
  (5, 5, '倉庫',            '2025-10-01', NULL, '新設');
