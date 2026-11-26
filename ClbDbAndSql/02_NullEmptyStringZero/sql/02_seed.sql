-- 第2回 検証用データ。すべて架空。
-- 実行例: sqlcmd -S <サーバー名> -E -C -f 65001 -i 02_seed.sql

use [clb_blog_02];
go

-- 再実行できるように空にする(truncate で identity も 1 始まりに戻る)
truncate table [dbo].[発注予定];
go

insert into [dbo].[発注予定] ([商品名], [発注数], [仕入先品番]) values
(N'ボールペン 黒',       10,   N'BP-100'),
(N'ボールペン 赤',       0,    N'BP-101'),
(N'A4 コピー用紙 500枚', null, N'CP-500'),
(N'クリアファイル 10枚', 5,    N''),
(N'感熱ロール紙',        null, null),
(N'付箋 75mm',           0,    null);
go
