# Capability: LINE通知

LINE Messaging APIを使用したプッシュ通知を担当する。

## ADDED Requirements

### Requirement: 新着商品の通知

システムは、新着商品が検出された場合、登録ユーザーにLINEプッシュ通知を送信しなければならない（SHALL）。

#### Scenario: 新着商品が1件以上ある場合

- **WHEN** `notified: false` の商品が1件以上存在する
- **AND** 通知が有効なユーザーが存在する
- **THEN** 新着商品をまとめた1通の通知が送信される
- **AND** 通知済み商品の `notified` が `true` に更新される

#### Scenario: 新着商品がない場合

- **WHEN** `notified: false` の商品が存在しない
- **THEN** 通知は送信されない

### Requirement: 通知メッセージフォーマット

システムは、複数の新着商品を1通のメッセージにまとめて送信しなければならない（SHALL）。

メッセージに含める情報:
- ソース名（Amazon, 楽天, etc）
- 商品タイトル
- 価格（取得できた場合）
- 商品URL
- 新着件数サマリー

#### Scenario: 複数ソースからの新着

- **WHEN** Amazon、楽天、アメブロから各1件の新着がある
- **THEN** 3件全てを1通のメッセージにまとめて送信する
- **AND** ソースごとにセクション分けして表示する

#### Scenario: 新着が10件を超える場合

- **WHEN** 新着商品が10件を超える
- **THEN** 上位10件を通知する
- **AND** 「他N件の新着があります」とサマリー表示する

### Requirement: ユーザー設定に基づく通知

システムは、ユーザーの設定に基づいて通知対象を決定しなければならない（SHALL）。

#### Scenario: 通知がOFFのユーザー

- **WHEN** ユーザーの `notification_enabled` が `false`
- **THEN** そのユーザーには通知を送信しない

#### Scenario: キーワードでフィルタリング

- **WHEN** ユーザーがカスタムキーワードを設定している
- **THEN** そのキーワードにマッチする商品のみを通知する

#### Scenario: ソースでフィルタリング

- **WHEN** ユーザーが監視ソースを限定している
- **THEN** 指定されたソースからの商品のみを通知する

### Requirement: 通知失敗時のリトライ

システムは、LINE API通知が失敗した場合、適切にリトライしなければならない（SHALL）。

#### Scenario: 一時的なエラー

- **WHEN** LINE APIが500エラーを返す
- **THEN** 指数バックオフでリトライする
- **AND** 3回失敗後はエラーログを記録して終了する

#### Scenario: ユーザーがブロックした場合

- **WHEN** LINE APIがユーザーブロックエラーを返す
- **THEN** そのユーザーの `notification_enabled` を `false` に更新する
- **AND** 警告ログを記録する
