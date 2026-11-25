-- 第2回 記事の前半(状態の列を足す前)を再現するためのテーブル。すべて架空データ。
-- 01 → 02 → 03 を流すと [発注予定] は後半の形(状態の列あり、仕入先品番 not null)になる。
-- 前半の画面(NULL と空文字が混ざった状態)も同じ デザイン から開けるように、前半の形のテーブルを別名で持つ。
-- 中身は 01_create_tables.sql と 02_seed.sql の [発注予定] と同じ。
-- 実行例: sqlcmd -S <サーバー名> -E -C -f 65001 -i 04_create_before_table.sql

use [clb_blog_02];
go

drop table if exists [dbo].[発注予定_変更前];
go

-- 発注数: null = 未定、0 = 今回は発注しない
-- 仕入先品番: null = 未確認、空文字 = 品番なし
create table [dbo].[発注予定_変更前] (
    [ID]         int identity(1,1) not null,
    [商品名]     nvarchar(100)     not null,
    [発注数]     int               null,
    [仕入先品番] nvarchar(20)      null,
    constraint [PK_発注予定_変更前] primary key ([ID])
);
go

insert into [dbo].[発注予定_変更前] ([商品名], [発注数], [仕入先品番]) values
(N'ボールペン 黒',       10,   N'BP-100'),
(N'ボールペン 赤',       0,    N'BP-101'),
(N'A4 コピー用紙 500枚', null, N'CP-500'),
(N'クリアファイル 10枚', 5,    N''),
(N'感熱ロール紙',        null, null),
(N'付箋 75mm',           0,    null);
go
