-- 検証用: not null の文字列列を、画面では必須にしない場合の動き
-- 備考A は既定値なし、備考B は既定値が空文字
-- 実行例: sqlcmd -S <サーバー名> -E -C -f 65001 -i 03_verify_notnull_text.sql

use [clb_blog_01];
go

create table [dbo].[検証メモ] (
    [ID]    int identity(1,1) not null,
    [件名]  nvarchar(50)      not null,
    [備考A] nvarchar(200)     not null,
    [備考B] nvarchar(200)     not null constraint [DF_検証メモ_備考B] default (''),
    constraint [PK_検証メモ] primary key ([ID])
);
go
