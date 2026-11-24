-- ClbEquipmentManagement：ログインとファイル添付のための基本のテーブル（NAK-04）
-- 対象：SQLite。データソース Main（main.db）に作る。001_tables.sql より先に流す。
-- 定義は CLB Starter（4314eff）の Empty テンプレートの DB と同じ定義
-- （template-create で作った main.db の sqlite_master から取り出したまま。行のデータはコピーしていない）

-- ログインするユーザー（AppUser モジュール）
CREATE TABLE app_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_name TEXT NOT NULL UNIQUE,
    name TEXT,
    hash TEXT NOT NULL,
    salt TEXT NOT NULL
, session_stamp TEXT);

-- アップロードした一時ファイルの管理（サーバーの appsettings.json の TemporaryFileTableInfo）
CREATE TABLE temporary_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    guid TEXT NOT NULL,
    created_date_time TEXT NULL
);

-- 最初の管理者（admin / admin）。手元で試すためのもの。ほかの人がアクセスできる場所で動かすときは、必ずパスワードを変える。
-- 出典：CLB Starter（4314eff）の README.md「本番の DB に最初の管理者を入れる」の 1 行をそのまま使っている
-- （ハッシュとソルトはテンプレートの SQLite と同じ値。パスワードは admin）
INSERT INTO app_users (user_name, name, hash, salt)
VALUES ('admin', '管理者', 'pUNVPHEWYngAim7aUFjf6kWtIROxrpzJPprcipyPujw=', 'CPYn8K+ecURogSHP5KTZ04lEbiAjZoq9wvwk5aIAQQg=');
