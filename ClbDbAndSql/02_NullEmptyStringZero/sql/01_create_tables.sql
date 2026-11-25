-- 第2回 検証用の「既存 DB」。すべて架空データ。
-- 実行例: sqlcmd -S <サーバー名> -E -C -f 65001 -i 01_create_tables.sql
-- 先にデータベースを作っておく: create database [clb_blog_02];

use [clb_blog_02];
go

drop table if exists [dbo].[発注予定];
go

-- 発注数: null = 未定、0 = 今回は発注しない
-- 仕入先品番: null = 未確認、空文字 = 品番なし
create table [dbo].[発注予定] (
    [ID]         int identity(1,1) not null,
    [商品名]     nvarchar(100)     not null,
    [発注数]     int               null,
    [仕入先品番] nvarchar(20)      null,
    constraint [PK_発注予定] primary key ([ID])
);
go
