-- 第2回 「未確認」と「なし」を状態の列で持つように変える。すべて架空データ。
-- 01_create_tables.sql と 02_seed.sql を流した状態(NULL = 未確認、空文字 = なし)に対して実行する。
-- 実行例: sqlcmd -S <サーバー名> -E -C -f 65001 -i 03_add_status_column.sql

use [clb_blog_02];
go

-- 品番確認済み: 0 = 未確認、1 = 確認済み(品番が空なら「なし」)
alter table [dbo].[発注予定]
    add [品番確認済み] bit not null
        constraint [DF_発注予定_品番確認済み] default 0;
go

-- 既存の行: 値がある行と空文字の行は確認済み。NULL の行は未確認のまま
update [dbo].[発注予定]
   set [品番確認済み] = 1
 where [仕入先品番] is not null;
go

-- 仕入先品番は空文字にそろえて not null にする
update [dbo].[発注予定]
   set [仕入先品番] = N''
 where [仕入先品番] is null;
go

alter table [dbo].[発注予定]
    alter column [仕入先品番] nvarchar(20) not null;
go

alter table [dbo].[発注予定]
    add constraint [DF_発注予定_仕入先品番] default N'' for [仕入先品番];
go
