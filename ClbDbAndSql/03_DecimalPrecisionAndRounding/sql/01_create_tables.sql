-- 第3回のサンプルの テーブル(既存の DB という想定)。すべて架空データ。
-- 実行例: sqlcmd -S <サーバー名> -E -C -f 65001 -i 01_create_tables.sql
-- 先にデータベースを作っておく: create database [clb_blog_03];

use [clb_blog_03];
go

drop table if exists [dbo].[見積明細];
go

-- 単価: 円未満2桁まで持つ(例: 12.50 円)
-- 数量: 小数3桁まで持つ(例: 1.005 kg)
-- 金額: 税抜。単価 × 数量 を円未満で丸めた値を保存する
create table [dbo].[見積明細] (
    [ID]     int identity(1,1) not null,
    [品名]   nvarchar(100)     not null,
    [単価]   decimal(10, 2)    not null,
    [数量]   decimal(8, 3)     not null,
    [金額]   decimal(12, 0)    null,
    constraint [PK_見積明細] primary key ([ID])
);
go
