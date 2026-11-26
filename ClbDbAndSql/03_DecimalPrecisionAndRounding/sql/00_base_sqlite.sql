-- ログイン用のテーブル(SQLite。データソース Main の main.db に作る)
-- 記事で使う SQL Server のテーブルとは別。アプリにログインするために必要。
-- 定義は Codeer.LowCode.Blazor.Starter(2026-11-25 取得の main)の「空のプロジェクト」テンプレートの DB と同じ。
-- 流し方は README の手順を参照(デザイナ の sql コマンドで流す)。

-- ログインするユーザー(AppUser モジュール)
CREATE TABLE app_users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_name TEXT NOT NULL UNIQUE,
    name TEXT,
    hash TEXT NOT NULL,
    salt TEXT NOT NULL,
    session_stamp TEXT
);

-- アップロードした一時ファイルの管理(サーバーの appsettings.json の TemporaryFileTableInfo)
CREATE TABLE temporary_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    guid TEXT NOT NULL,
    created_date_time TEXT NULL
);

-- 最初の管理者(admin / admin)。手元で試すためのもの。
-- ほかの人がアクセスできる場所で動かすときは、必ずパスワードを変える。
-- 出典: Codeer.LowCode.Blazor.Starter の README.md「本番の DB に最初の管理者を入れる」の行
INSERT INTO app_users (user_name, name, hash, salt)
VALUES ('admin', '管理者', 'pUNVPHEWYngAim7aUFjf6kWtIROxrpzJPprcipyPujw=', 'CPYn8K+ecURogSHP5KTZ04lEbiAjZoq9wvwk5aIAQQg=');
