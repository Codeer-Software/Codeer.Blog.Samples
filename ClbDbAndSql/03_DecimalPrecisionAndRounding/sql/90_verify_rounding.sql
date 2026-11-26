-- 第3回 検証用: 列の位取りを超える値を update したときに、SQL Server がどう丸めるかを直接確かめる。
-- 画面から保存したときと同じ値を、パラメータ(sp_executesql)とリテラルの両方で流す。
-- 最後に rollback するので、データは変わらない。
-- 実行例: sqlcmd -S <サーバー名> -E -C -f 65001 -i 90_verify_rounding.sql

use [clb_blog_03];
go

set nocount on;
begin transaction;

-- 1. パラメータで渡す(型は、値の桁から決まる形にしてある)
exec sp_executesql N'update [見積明細] set [単価]=@p0 where [ID]=@pid0', N'@p0 numeric(5,3), @pid0 int', @p0 = 12.345,  @pid0 = 1;
exec sp_executesql N'update [見積明細] set [単価]=@p0 where [ID]=@pid0', N'@p0 numeric(5,3), @pid0 int', @p0 = 13.355,  @pid0 = 2;
exec sp_executesql N'update [見積明細] set [数量]=@p0 where [ID]=@pid0', N'@p0 numeric(5,4), @pid0 int', @p0 = 1.0005,  @pid0 = 3;
exec sp_executesql N'update [見積明細] set [金額]=@p0 where [ID]=@pid0', N'@p0 numeric(3,1), @pid0 int', @p0 = 12.5,    @pid0 = 4;
exec sp_executesql N'update [見積明細] set [金額]=@p0 where [ID]=@pid0', N'@p0 numeric(3,1), @pid0 int', @p0 = 13.5,    @pid0 = 5;
exec sp_executesql N'update [見積明細] set [金額]=@p0 where [ID]=@pid0', N'@p0 numeric(1,1), @pid0 int', @p0 = 0.4,     @pid0 = 6;

select N'パラメータ' as [渡し方], [ID], [単価], [数量], [金額] from [dbo].[見積明細] order by [ID];

rollback transaction;
go

set nocount on;
begin transaction;

-- 2. リテラルで書く
update [dbo].[見積明細] set [単価] = 12.345 where [ID] = 1;
update [dbo].[見積明細] set [単価] = 13.355 where [ID] = 2;
update [dbo].[見積明細] set [数量] = 1.0005 where [ID] = 3;
update [dbo].[見積明細] set [金額] = 12.5   where [ID] = 4;
update [dbo].[見積明細] set [金額] = 13.5   where [ID] = 5;
update [dbo].[見積明細] set [金額] = 0.4    where [ID] = 6;

select N'リテラル' as [渡し方], [ID], [単価], [数量], [金額] from [dbo].[見積明細] order by [ID];

rollback transaction;
go

-- 3. 丸め方の確認: 列に入れるときの暗黙の変換、cast、round
set nocount on;
select
    cast(12.345 as decimal(10,2)) as [cast 12.345],
    cast(12.344 as decimal(10,2)) as [cast 12.344],
    cast(-12.345 as decimal(10,2)) as [cast -12.345],
    cast(12.5 as decimal(12,0))   as [cast 12.5],
    cast(13.5 as decimal(12,0))   as [cast 13.5],
    round(12.5, 0)                as [round 12.5],
    round(13.5, 0)                as [round 13.5],
    round(12.345, 2, 1)           as [round 12.345 切り捨て];
go

-- 4. 整数部が列の精度を超える場合
set nocount on;
begin transaction;
begin try
    update [dbo].[見積明細] set [単価] = 123456789 where [ID] = 1;
    select N'保存された' as [結果];
end try
begin catch
    select error_number() as [エラー番号], error_message() as [メッセージ];
end catch;
rollback transaction;
go
