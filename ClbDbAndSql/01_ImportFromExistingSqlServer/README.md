# 01_ImportFromExistingSqlServer

Qiita の記事「[既存の SQL Server から Codeer.LowCode.Blazor (CLB) の管理画面を作るまで](https://qiita.com/shinsuke-oda/items/2d2f12281f6bac463ca7)」のサンプルです。

すでにテーブルがある SQL Server に CLB をつなぎ、テーブルからモジュールを取り込んで、一覧と詳細の画面を作るまでのサンプルです。
このフォルダに入っているのは、記事の最後の状態(既存のテーブルに合わせて調整したあと)です。

> 筆者は株式会社Codeerの社員で、Codeer.LowCode.Blazor(CLB)の開発元に所属しています。

## 対象の版

確認日: 2026-11-12

| 項目 | 版 |
| --- | --- |
| CLB | Codeer.LowCode.Blazor 1.3.66 / Designer 1.3.67 / Designer.Standard 0.8.29 / DbAccess 0.2.5 |
| 元にしたもの | [Codeer.LowCode.Blazor.Starter](https://github.com/Codeer-Software/Codeer.LowCode.Blazor.Starter) の Cookie ホスト(2026-11-12 取得の main)。デザインプロジェクトは「空のプロジェクト」テンプレート |
| .NET SDK | 10.0.403 |
| DB | SQL Server 2025 Developer Edition(記事のテーブル)、SQLite(ログイン用) |
| OS | Windows 11 Pro |

## フォルダ構成

```
01_ImportFromExistingSqlServer/
├─ sql/                          DB を作る SQL(下の表)
└─ LowCodeApp/                   CLB Starter から書き出したアプリ
   ├─ Source/                    ホストのソース(LowCodeApp.sln)
   ├─ DesignProjects/Project/
   │  ├─ design/                 デザイン本体(Modules、PageFrames)
   │  └─ designer.settings.Development.example.json   デザイナの設定の見本
   └─ CLAUDE.md、AGENTS.md、AIForDeveloper/、.vscode/   CLB Starter に付属のもの
```

| SQL | 流す先 | 内容 |
| --- | --- | --- |
| `00_base_sqlite.sql` | SQLite(main.db) | ログイン用のテーブルと、最初の管理者(admin / admin) |
| `01_create_tables.sql` | SQL Server | `商品` と `顧客` のテーブル。記事の「サンプル の DB」の DDL |
| `02_seed.sql` | SQL Server | 架空のデータ |
| `03_verify_notnull_text.sql` | SQL Server | 記事の「既定値のある列は、画面の初期値を DB とそろえる」の後半で使った確認用のテーブル(`検証メモ`)。このフォルダのデザインには画面を入れていないので、流さなくても動きます |

## 動かし方

PowerShell で、同じ画面のまま上から順に実行します(途中で作る変数を、あとの手順でも使います)。
必要なものは、[上の階層の README](../README.md) に書いています。

1. クローンして、このフォルダに移る。

   ```powershell
   git clone https://github.com/Codeer-Software/Codeer.Blog.Samples.git
   cd Codeer.Blog.Samples\ClbDbAndSql\01_ImportFromExistingSqlServer
   ```

2. 自分の SQL Server の名前を変数に入れる。名前付きインスタンスなら `.\SQLEXPRESS` のように書きます。

   ```powershell
   $server = "localhost"
   ```

3. SQL Server にデータベース `clb_blog_01` を作り、テーブルと架空のデータを入れる。

   ```powershell
   sqlcmd -S $server -E -C -Q "create database [clb_blog_01]"
   foreach ($f in "01_create_tables.sql", "02_seed.sql") {
     sqlcmd -S $server -E -C -f 65001 -b -i "sql\$f"
     "$f : 終了コード $LASTEXITCODE"
   }
   ```

   どれも終了コードが 0 なら成功です。`-f 65001` は、日本語のテーブル名と列名を UTF-8 で読ませるための指定です。

4. ログイン用の DB とデザインの保存先を作る。

   ```powershell
   New-Item -ItemType Directory -Force C:\ClbDbAndSql.Local\01\Data, C:\ClbDbAndSql.Local\01\Designs, C:\ClbDbAndSql.Local\01\Storages, C:\ClbDbAndSql.Local\01\Font | Out-Null
   ```

5. デザイナの設定ファイルを、見本からコピーする。

   ```powershell
   cd LowCodeApp
   Copy-Item DesignProjects\Project\designer.settings.Development.example.json DesignProjects\Project\design\designer.settings.Development.json
   ```

6. 手順2で `$server` を `localhost` 以外にした場合は、設定ファイル2つの接続文字列を書き換える。`localhost` のままなら、この手順は要りません。

   ```powershell
   $escaped = $server.Replace("\", "\\")
   foreach ($f in "DesignProjects\Project\design\designer.settings.Development.json", "Source\LowCodeApp.Server\appsettings.Development.json") {
     $text = [System.IO.File]::ReadAllText((Resolve-Path $f))
     [System.IO.File]::WriteAllText((Resolve-Path $f), $text.Replace("Server=localhost;", "Server=$escaped;"))
   }
   ```

7. ビルドする。CLB の試用は、ここで始まります(デザイナのコマンドは、試用が始まっていないと動きません)。

   ```powershell
   dotnet build Source\LowCodeApp.sln
   ```

8. ログイン用の DB を作る。`C:\ClbDbAndSql.Local\01\Data\main.db` ができます。

   ```powershell
   $designer = (Resolve-Path "Source\LowCodeApp.Designer\bin\Debug\net10.0-windows\LowCodeApp.Designer.exe").Path
   $design   = (Resolve-Path "DesignProjects\Project\design").Path
   $p = Start-Process -FilePath $designer -Wait -PassThru -ArgumentList @(
     "sql", $design, "--datasource", "Main",
     "--file", (Resolve-Path "..\sql\00_base_sqlite.sql").Path,
     "--out", "$env:TEMP\clb_base.json")
   "00_base_sqlite : 終了コード $($p.ExitCode)"
   ```

   終了コードが 0 なら成功です。0 でないときは、`$env:TEMP\clb_base.json` にエラーの内容が書かれています。
   テーブルがすでにあると失敗するので、やり直すときは `C:\ClbDbAndSql.Local\01\Data\main.db` を消してから流します。

9. デザインをデプロイする。`C:\ClbDbAndSql.Local\01\Designs\App.zip` ができます。

   ```powershell
   $p = Start-Process -FilePath $designer -Wait -PassThru -ArgumentList @("deploy", $design, "--out", "$env:TEMP\clb_deploy.json")
   "deploy : 終了コード $($p.ExitCode)"
   Get-Content "$env:TEMP\clb_deploy.json"
   ```

   `"success": true` なら成功です。

10. サーバーを起動して、ブラウザで開く。

    ```powershell
    dotnet run --project Source\LowCodeApp.Server --launch-profile https
    ```

    `https://localhost:7137` を開き、`admin` / `admin` でログインします。このユーザーは手元で試すためのものです。ほかの人がアクセスできる場所で動かすときは、必ずパスワードを変えてください。
    証明書の警告が出る場合は、`dotnet dev-certs https --trust` を実行して、開発用の証明書を信頼してください。
    サーバーは、起動したターミナルで Ctrl+C を押すと止まります。

発行された SQL は、サーバーを起動したターミナルに出ます(`appsettings.Development.json` の `SqlLog` を `true` にしてあります)。記事に載せた SQL と見比べられます。

デザイナで設定を見るときは、次のコマンドで開きます。見るだけのときは、保存せずに閉じてください。

```powershell
& $designer $design
```

## 画面と記事の対応

サイドメニューの項目と、記事で扱っている内容の対応です。

| サイドメニュー | 内容 |
| --- | --- |
| 顧客 | `顧客` の一覧と詳細。主キーの置き換え、チェックボックスの初期値(スクリプト `顧客.mod.cs`)、登録日時と更新日時の自動設定、コード順の並び |
| 商品 | `商品` の一覧と詳細。必須を外したチェックボックス、項目の並び順 |
| AppUser | ログインするユーザーの管理(CLB Starter のテンプレートのまま) |

- 記事と同じ版(Codeer.LowCode.Blazor 1.3.66)のままにしています。そのため、ビルドで警告 `NU1903` が出ます(依存しているパッケージ `Microsoft.AspNetCore.WebUtilities` 10.0.14 に、既知の脆弱性があるという警告)。手元で試す分には動きます。新しい版で試す場合は、`LowCodeApp/AIForDeveloper/claude-code-update.md` の手順でパッケージを上げてください。[02_NullEmptyStringZero](../02_NullEmptyStringZero/) は、この警告が出ない版です。
- 画面から保存や削除をすると、データが変わります。最初の状態に戻すときは、SQL Server 用の SQL を 01 から順に流し直します。

## 片付け

- SQL Server のデータベース: `sqlcmd -S $server -E -C -Q "drop database [clb_blog_01]"`
- ログイン用の DB とデプロイ先: `C:\ClbDbAndSql.Local\01` フォルダを消す
