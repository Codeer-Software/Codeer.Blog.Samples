# ClbDbAndSql

Qiita の連載で使ったサンプルです。DB と SQL の側から Codeer.LowCode.Blazor(CLB)を見ていく連載です。
記事を読みながら、同じ画面と同じ SQL を手元で試せます。

> 筆者は株式会社Codeerの社員で、Codeer.LowCode.Blazor(CLB)の開発元に所属しています。

## 記事との対応

回ごとに、アプリとテーブルを分けています。回をまたいで同じアプリを育てる作りではないので、読みたい回のフォルダだけで動かせます。

| フォルダ | 記事 | 内容 |
| --- | --- | --- |
| [01_ImportFromExistingSqlServer](01_ImportFromExistingSqlServer/) | [既存の SQL Server から Codeer.LowCode.Blazor (CLB) の管理画面を作るまで](https://qiita.com/shinsuke-oda/items/2d2f12281f6bac463ca7) | 既存のテーブルを取り込んで、一覧と詳細の画面を作る |
| [02_NullEmptyStringZero](02_NullEmptyStringZero/) | [NULL・空文字・0 を Codeer.LowCode.Blazor (CLB) の画面で混同しない](https://qiita.com/shinsuke-oda/items/54b1fad21c6146d9146a) | NULL・空文字・0 の表示、保存、検索での扱いと、状態の列への作り替え |
| [03_DecimalPrecisionAndRounding](03_DecimalPrecisionAndRounding/) | [金額と数量を Codeer.LowCode.Blazor (CLB) で扱う前に、桁と丸めを決める](https://qiita.com/shinsuke-oda/items/0b1ae9400157fa3faa9f) | 数値のフィールドの桁の設定と、スクリプトでの金額の計算と丸め方 |

動かし方は、それぞれのフォルダの README に書いています。

## このサンプルについて

- テーブルのデータは、すべて架空のものです。
- 記事で使う業務のテーブルは SQL Server に置きます。ログイン用のテーブルだけ SQLite に置きます(CLB Starter の初期の構成のまま)。
- 学習・評価用のサンプルです。そのまま本番で使うことは想定していません。

## 必要なもの

- Windows(デザイナが Windows のアプリのため。確認は Windows 11)
- .NET 10 SDK
- SQL Server と `sqlcmd`(確認は SQL Server 2025 Developer Edition。Windows 認証でつなぎます)
- Git
- インターネット接続(最初のビルドで NuGet のパッケージを取得します)
- CLB のライセンスは要りません。30日間の無料試用で動きます。試用は最初のビルドで始まります。評価目的に限ります。

## ライセンス

- このフォルダのコードは、リポジトリの [LICENSE](../LICENSE)(MIT)に従います。
- CLB 本体は商用製品で、MIT ではありません。評価目的であれば30日間の無料試用で動かせます。商用で使うにはライセンスが必要です。条件は [CLB製品ページ](https://www.codeer.co.jp/LowCode) で確認してください。

## 秘密情報について

接続文字列は、`localhost` に Windows 認証でつなぐ見本の値だけをコミットしています。パスワードやライセンスキーは含めていません。
手元の SQL Server の名前は、各回の README の手順で設定してください。
