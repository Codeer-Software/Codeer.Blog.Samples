# 02_NullEmptyStringZero

Qiita の記事「[NULL・空文字・0 を Codeer.LowCode.Blazor (CLB) の画面で混同しない](https://qiita.com/shinsuke-oda/items/54b1fad21c6146d9146a)」のサンプルです。

NULL と空文字、NULL と 0 に別々の意味を持たせているテーブルを CLB の画面に出して、表示・保存・検索での扱いを確かめるサンプルです。
記事の前半(状態の列を足す前)と後半(足したあと)の両方を、1つのアプリのサイドメニューから開けます。

> 筆者は株式会社Codeerの社員で、Codeer.LowCode.Blazor(CLB)の開発元に所属しています。

## 対象の版

確認日: 2026-11-19

| 項目 | 版 |
| --- | --- |
| CLB | Codeer.LowCode.Blazor 1.3.69 / Designer 1.3.70 / Designer.Standard 0.8.30 / DbAccess 0.2.6 |
| 元にしたもの | [Codeer.LowCode.Blazor.Starter](https://github.com/Codeer-Software/Codeer.LowCode.Blazor.Starter) の Cookie ホスト(2026-11-19 取得の main)。デザインプロジェクトは「空のプロジェクト」テンプレート |
| .NET SDK | 10.0.403 |
| DB | SQL Server 2025 Developer Edition(記事のテーブル)、SQLite(ログイン用) |
| OS | Windows 11 Pro |

## フォルダ構成

```
02_NullEmptyStringZero/
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
| `01_create_tables.sql` | SQL Server | `発注予定` のテーブル。記事の「サンプル の DB」の DDL |
| `02_seed.sql` | SQL Server | 架空のデータ(6行) |
| `03_add_status_column.sql` | SQL Server | `発注予定` に状態の列 `品番確認済み` を足し、`仕入先品番` を空文字にそろえる。記事の後半の形になる |
| `04_create_before_table.sql` | SQL Server | 記事の前半の形(01・02 を流した直後と同じ定義とデータ)を、別名のテーブル `発注予定_変更前` として作る |

## 動かし方

PowerShell で、同じ画面のまま上から順に実行します(途中で作る変数を、あとの手順でも使います)。
必要なものは、[上の階層の README](../README.md) に書いています。

1. クローンして、このフォルダに移る。

   ```powershell
   git clone https://github.com/Codeer-Software/Codeer.Blog.Samples.git
   cd Codeer.Blog.Samples\ClbDbAndSql\02_NullEmptyStringZero
   ```

2. 自分の SQL Server の名前を変数に入れる。名前付きインスタンスなら `.\SQLEXPRESS` のように書きます。

   ```powershell
   $server = "localhost"
   ```

3. SQL Server にデータベース `clb_blog_02` を作り、テーブルと架空のデータを入れる。

   ```powershell
   sqlcmd -S $server -E -C -Q "create database [clb_blog_02]"
   foreach ($f in "01_create_tables.sql", "02_seed.sql", "03_add_status_column.sql", "04_create_before_table.sql") {
     sqlcmd -S $server -E -C -f 65001 -b -i "sql\$f"
     "$f : 終了コード $LASTEXITCODE"
   }
   ```

   どれも終了コードが 0 なら成功です。`-f 65001` は、日本語のテーブル名と列名を UTF-8 で読ませるための指定です。

4. ログイン用の DB とデザインの保存先を作る。

   ```powershell
   New-Item -ItemType Directory -Force C:\ClbDbAndSql.Local\02\Data, C:\ClbDbAndSql.Local\02\Designs, C:\ClbDbAndSql.Local\02\Storages, C:\ClbDbAndSql.Local\02\Font | Out-Null
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

8. ログイン用の DB を作る。`C:\ClbDbAndSql.Local\02\Data\main.db` ができます。

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
   テーブルがすでにあると失敗するので、やり直すときは `C:\ClbDbAndSql.Local\02\Data\main.db` を消してから流します。

9. デザインをデプロイする。`C:\ClbDbAndSql.Local\02\Designs\App.zip` ができます。

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
| 状態の列を足す前 / 発注予定 | 記事の前半。`発注予定_変更前` の一覧と詳細。NULL と空文字の表示、「編集後の空文字の値」での保存、「空」「空以外」の検索 |
| 状態の列を足したあと / 発注予定 | 記事の後半。状態の列 `品番確認済み` のチェックボックスと、検索欄(`品番確認済み` のプルダウン、`発注数` の2つの検索欄を OR でつないだもの) |
| 状態の列を足したあと / 品番未確認 | 固定の条件: `品番確認済み` が外れている |
| 状態の列を足したあと / 品番未確認(1 以上) | 固定の条件に `発注数` の下限 1 を足したもの。NULL の行も該当しなくなり、0件になる例 |
| 状態の列を足したあと / 品番未確認(0 を除く) | 固定の条件を「下限 1、または空である」にしたもの。NULL の行が残る例 |
| 状態の列を足したあと / 品番なし | 固定の条件: `品番確認済み` が入っている、かつ `仕入先品番` が空である |
| AppUser | ログインするユーザーの管理(CLB Starter のテンプレートのまま) |

- 記事の「保存される値」の表にある `Null` の列は、`発注予定_変更前` の `仕入先品番` の「編集後の空文字の値」を「Null」に変えて試した結果です。このフォルダのデザインは既定の「空文字」のままです。試すときは、デザイナで変更してデプロイし直します。
- 画面から保存や削除をすると、データが変わります。最初の状態に戻すときは、SQL Server 用の SQL を 01 から順に流し直します。

## 片付け

- SQL Server のデータベース: `sqlcmd -S $server -E -C -Q "drop database [clb_blog_02]"`
- ログイン用の DB とデプロイ先: `C:\ClbDbAndSql.Local\02` フォルダを消す
