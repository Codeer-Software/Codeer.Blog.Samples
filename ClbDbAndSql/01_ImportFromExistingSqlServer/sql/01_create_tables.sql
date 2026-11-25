-- 第1回 検証用の「既存 DB」。すべて架空データ。
-- 実行例: sqlcmd -S <サーバー名> -E -C -f 65001 -i 01_create_tables.sql
-- 先にデータベースを作っておく: create database [clb_blog_01];

use [clb_blog_01];
go

drop table if exists [dbo].[顧客];
drop table if exists [dbo].[商品];
go

-- 主キーの列名が ID のテーブル
create table [dbo].[商品] (
    [ID]         int identity(1,1) not null,
    [商品コード] nvarchar(10)      not null,
    [商品名]     nvarchar(100)     not null,
    [単価]       decimal(10, 2)    not null,
    [取扱終了]   bit               not null constraint [DF_商品_取扱終了] default (0),
    constraint [PK_商品] primary key ([ID]),
    constraint [UX_商品_商品コード] unique ([商品コード])
);
go

-- 主キーの列名が ID ではないテーブル
create table [dbo].[顧客] (
    [顧客ID]     int identity(1,1) not null,
    [顧客コード] nvarchar(10)      not null,
    [顧客名]     nvarchar(100)     not null,
    [電話番号]   nvarchar(20)      null,
    [取引中]     bit               not null constraint [DF_顧客_取引中] default (1),
    [登録日時]   datetime2(0)      not null constraint [DF_顧客_登録日時] default (sysdatetime()),
    [更新日時]   datetime2(0)      null,
    constraint [PK_顧客] primary key ([顧客ID]),
    constraint [UX_顧客_顧客コード] unique ([顧客コード])
);
go
