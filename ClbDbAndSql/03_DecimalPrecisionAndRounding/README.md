# 03_DecimalPrecisionAndRounding

Qiita の記事「[金額と数量を Codeer.LowCode.Blazor (CLB) で扱う前に、桁と丸めを決める](https://qiita.com/shinsuke-oda/items/0b1ae9400157fa3faa9f)」のサンプルです。

単価・数量・金額を `decimal` の列で持つテーブルを CLB の画面に出して、列の桁を超える値を保存したときの結果と、数値のフィールドの設定(フォーマット、最小値、最大値、ステップ、小数点以下有効桁数)、スクリプトでの金額の計算と丸め方を確かめるサンプルです。
取り込んだ直後の画面と、設定を足した画面を、1つのアプリのサイドメニューから開けます。どの画面も同じテーブル `見積明細` を見ています。

> 筆者は株式会社Codeerの社員で、Codeer.LowCode.Blazor(CLB)の開発元に所属しています。

## 対象の版

確認日: 2026-11-25

| 項目 | 版 |
| --- | --- |
| CLB | Codeer.LowCode.Blazor 1.3.72 / Designer 1.3.74 / Designer.Standard 0.8.31 / DbAccess 0.2.6 |
| 元にしたもの | [Codeer.LowCode.Blazor.Starter](https://github.com/Codeer-Software/Codeer.LowCode.Blazor.Starter) の Cookie ホスト(2026-11-25 取得の main)。デザインプロジェクトは「空のプロジェクト」テンプレート |
| .NET SDK | 10.0.403 |
| DB | SQL Server 2025 Developer Edition(記事のテーブル)、SQLite(ログイン用) |
| OS | Windows 11 Pro |

## フォルダ構成

```
03_DecimalPrecisionAndRounding/
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
| `01_create_tables.sql` | SQL Server | `見積明細` のテーブル。記事の「サンプル の DB」の DDL |
| `02_seed.sql` | SQL Server | 架空のデータ(6行)。`金額` は NULL |
| `90_verify_rounding.sql` | SQL Server | 列の小数の桁数を超える値を update したときに SQL Server がどう丸めるかを、画面を通さずに確かめる SQL。最後に rollback するのでデータは変わりません。流さなくても動きます |

## 動かし方

PowerShell で、同じ画面のまま上から順に実行します(途中で作る変数を、あとの手順でも使います)。
必要なものは、[上の階層の README](../README.md) に書いています。

1. クローンして、このフォルダに移る。

   ```powershell
   git clone https://github.com/Codeer-Software/Codeer.Blog.Samples.git
   cd Codeer.Blog.Samples\ClbDbAndSql\03_DecimalPrecisionAndRounding
   ```

2. 自分の SQL Server の名前を変数に入れる。名前付きインスタンスなら `.\SQLEXPRESS` のように書きます。

   ```powershell
   $server = "localhost"
   ```

3. SQL Server にデータベース `clb_blog_03` を作り、テーブルと架空のデータを入れる。

   ```powershell
   sqlcmd -S $server -E -C -Q "create database [clb_blog_03]"
   foreach ($f in "01_create_tables.sql", "02_seed.sql") {
     sqlcmd -S $server -E -C -f 65001 -b -i "sql\$f"
     "$f : 終了コード $LASTEXITCODE"
   }
   ```

   どれも終了コードが 0 なら成功です。`-f 65001` は、日本語のテーブル名と列名を UTF-8 で読ませるための指定です。

4. ログイン用の DB とデザインの保存先を作る。

   ```powershell
   New-Item -ItemType Directory -Force C:\ClbDbAndSql.Local\03\Data, C:\ClbDbAndSql.Local\03\Designs, C:\ClbDbAndSql.Local\03\Storages, C:\ClbDbAndSql.Local\03\Font | Out-Null
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

8. ログイン用の DB を作る。`C:\ClbDbAndSql.Local\03\Data\main.db` ができます。

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
   テーブルがすでにあると失敗するので、やり直すときは `C:\ClbDbAndSql.Local\03\Data\main.db` を消してから流します。

9. デザインをデプロイする。`C:\ClbDbAndSql.Local\03\Designs\App.zip` ができます。

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
| 取り込み直後 | `見積明細` を取り込んだままの画面。数値のフィールドの設定は空。記事の「列の桁を超える値を保存する」は、この画面で試します |
| 桁をそろえる | 数値のフィールドに、フォーマット、最小値、最大値、ステップ、小数点以下有効桁数を設定した画面。小数点以下有効桁数の切り捨て、最大値のチェック、一覧の桁区切り |
| フォーマット の書き方 | `単価` の列を、フォーマットだけ変えて一覧に並べた画面(`#,##0.00`、`#,##0`、`#,##0.#`、空) |
| 金額を計算する | `単価` か `数量` を変えると、スクリプト(`見積明細_計算.mod.cs`)が `金額` を計算する画面。丸め方ごとの結果を並べて表示します |
| AppUser | ログインするユーザーの管理(CLB Starter のテンプレートのまま) |

- 4つの画面は同じテーブルを見ています。ある画面で保存した値は、ほかの画面にも出ます。
- 記事の「フォーマット は表示専用のときに効く」の表にある大きな値(1234567.5 など)と 12345.67 は、画面から `単価` などを書き換えて保存したときの表示です。最初のデータには入っていません。
- 画面から保存や削除をすると、データが変わります。最初の状態に戻すときは、`02_seed.sql` を流し直します。

## 片付け

- SQL Server のデータベース: `sqlcmd -S $server -E -C -Q "drop database [clb_blog_03]"`
- ログイン用の DB とデプロイ先: `C:\ClbDbAndSql.Local\03` フォルダを消す
