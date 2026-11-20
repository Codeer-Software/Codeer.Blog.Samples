# ClbEquipmentManagement

Qiita の連載「組み込み機器と業務画面の境界・連携・現場運用」で使う共通サンプルです。
架空の設備管理アプリを、記事ごとに少しずつ育てていきます。

> 筆者は株式会社Codeerの社員で、Codeer.LowCode.Blazor（CLB）の開発元に所属しています。

## このサンプルについて

- 設備・機種・計測値などのデータは、すべて架空のものです。実在の機器や現場とは関係ありません。
- PLC・MQTT・シリアル通信・C++ との連携は、CLB の標準機能ではありません。CLB とは別に作るアダプターとして実装します。
- CLB は管理画面と業務データを担当します。リアルタイム制御には使いません。安全に関わる判断は機器側に残します。
- 学習・評価用のサンプルです。そのまま本番で使うことは想定していません。

## 対象の版

| 項目 | 版 |
| --- | --- |
| Codeer.LowCode.Blazor | 1.3.70（[CLB Starter](https://github.com/Codeer-Software/Codeer.LowCode.Blazor.Starter) のコミット 4314eff を元にしている） |
| .NET SDK | 10.0（確認は 10.0.404。`global.json` で 10.0 系に固定） |
| DB | SQLite |
| 開発環境 | VS Code（C# Dev Kit） |
| OS | （確認して記入） |

確認日：（最初のコミット時に記入）

## ライセンス

- このフォルダのコードは、リポジトリの [LICENSE](../LICENSE)（MIT）に従います。
- CLB 本体は商用製品で、MIT ではありません。評価目的であれば30日間の無料試用で動かせます。商用で使うにはライセンスが必要です。条件は [CLB製品ページ](https://www.codeer.co.jp/LowCode) で確認してください。

## フォルダ構成

```
ClbEquipmentManagement/
├─ global.json                 .NET 10 に固定
├─ Source/Hosts/Cookie/        CLB Starter の構成（LowCodeApp.sln ほか）
├─ Source/Hosts/Common/        デザイナなど
├─ DesignProjects/EquipmentManagement/   画面とモジュールの定義
├─ Database/                   テーブル定義と架空データの SQL（NAK-04 から）
├─ Simulator/                  機器シミュレーター（NAK-06 から）
└─ Adapters/                   MQTT・シリアル・C++ のアダプター（NAK-07 以降）
```

まだ作っていないフォルダもあります。記事の進み具合に合わせて追加します。

## 動かし方

（NAK-04 の実装後に記入）

DB とファイルの保存先は、`C:\ClbEquipmentManagement.Local\` 以下を使います。
CLB Starter の初期設定（`C:\Codeer.LowCode.Blazor.Local\`）とは分けています。

## 記事との対応

記事ごとにタグを付けています。記事を書いた時点のコードは、タグを選ぶと見られます。

| タグ | 記事 | 内容 |
| --- | --- | --- |
| NAK-04 | （公開後に記入） | 型番と個体を分ける設備台帳 |

## 秘密情報について

接続文字列、ライセンスキー、パスワードなどはコミットしていません。
手元で必要な値は、各自の環境で設定してください。
