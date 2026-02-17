# Tasks: ボンボンドロップシール販売通知システム

## 1. プロジェクト初期設定

- [x] 1.1 Ruby 3.2+ プロジェクト初期化（Gemfile作成）
- [x] 1.2 AWS SAM テンプレート (`template.yaml`) 作成
- [x] 1.3 ディレクトリ構成作成
- [x] 1.4 RSpec設定
- [x] 1.5 .env.example と環境変数設計

## 2. DynamoDB テーブル設計・構築

- [x] 2.1 Productsテーブル定義（SAMテンプレート）
- [x] 2.2 Usersテーブル定義（SAMテンプレート）
- [x] 2.3 GSI設計（notified商品取得用）
- [ ] 2.4 DynamoDBクライアントラッパー作成 (`lib/dynamodb_client.rb`)
- [ ] 2.5 Productモデル作成 (`models/product.rb`)
- [ ] 2.6 Userモデル作成 (`models/user.rb`)

## 3. スクレイピング機能実装

### 3.1 基盤

- [ ] 3.1.1 Baseスクレイパークラス作成 (`scrapers/base.rb`)
- [ ] 3.1.2 重複排除サービス作成 (`services/deduplicator.rb`)

### 3.2 ECサイトスクレイパー

- [ ] 3.2.1 楽天商品検索API連携 (`scrapers/rakuten.rb`)
- [ ] 3.2.2 Yahoo!ショッピングAPI連携 (`scrapers/yahoo.rb`)

### 3.3 ブログスクレイパー

- [ ] 3.3.1 アメブロRSS/スクレイパー (`scrapers/ameblo.rb`)

### 3.4 スクレイパーLambdaハンドラ

- [ ] 3.4.1 Lambdaハンドラ作成 (`handlers/scraper.rb`)
- [ ] 3.4.2 EventBridgeスケジュール設定（SAMテンプレート）

## 4. LINE通知機能実装

- [ ] 4.1 LINE Messaging APIクライアント (`services/line_client.rb`)
- [ ] 4.2 通知メッセージフォーマッター (`services/message_formatter.rb`)
- [ ] 4.3 通知サービス (`services/notifier.rb`)
- [ ] 4.4 Notifier Lambdaハンドラ (`handlers/notifier.rb`)
- [ ] 4.5 DynamoDB Streams または SQS連携設定

## 5. LINE Webhook機能実装

- [ ] 5.1 Webhook署名検証
- [ ] 5.2 コマンドパーサー
- [ ] 5.3 友だち追加イベントハンドラ
- [ ] 5.4 メッセージイベントハンドラ（コマンド処理）
- [ ] 5.5 Webhook Lambdaハンドラ (`handlers/webhook.rb`)
- [ ] 5.6 API Gateway設定（SAMテンプレート）

## 6. テスト

- [ ] 6.1 モデルのユニットテスト
- [ ] 6.2 スクレイパーのユニットテスト（モック使用）
- [ ] 6.3 サービスのユニットテスト
- [ ] 6.4 Lambdaハンドラの統合テスト

## 7. デプロイ・運用設定

- [ ] 7.1 SAM build/deploy 動作確認
- [ ] 7.2 Lambda Layer（Nokogiri等）設定
- [ ] 7.3 Secrets Manager または Parameter Store 設定（APIキー管理）
- [ ] 7.4 CloudWatch Logs設定
- [ ] 7.5 エラーアラート設定（SNS）

## 8. LINE公式アカウント設定

- [x] 8.1 LINE Developersコンソールでチャネル作成
- [x] 8.2 Messaging API設定
- [ ] 8.3 Webhook URL設定（デプロイ後に設定）
- [ ] 8.4 リッチメニュー設定（任意）

## 9. 外部API設定

- [x] 9.1 楽天API アプリID取得
- [x] 9.2 Yahoo! デベロッパーAPI設定

## 依存関係

```
1 → 2 → 3 → 4 → 5 → 6 → 7
                ↓
                8, 9（並行可能）
```

## 検証ポイント

- [ ] ローカル環境でsam local invoke動作確認
- [ ] 各APIからの商品情報取得確認
- [ ] DynamoDBへの保存・重複排除確認
- [ ] LINE通知の受信確認
- [ ] コマンドによる設定変更確認
