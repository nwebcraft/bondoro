# Bondoro - ボンボンドロップシール販売通知ツール

クーリア（Q-LiA）のボンボンドロップシール（BONBON DROP）の販売・入荷情報を自動収集し、LINEで通知するツールです。

## 概要

平成レトロブームで大人気のボンボンドロップシールは入手困難になることも。このツールは複数のECサイトとブログを定期的に監視し、新着情報をLINEでお知らせします。

## 機能

- **自動監視**: Amazon、楽天市場、Yahoo!ショッピング、アメブロを定期チェック
- **LINE通知**: 新着情報をLINEプッシュ通知でお届け
- **重複排除**: 同じ商品の重複通知を防止
- **カスタマイズ**: 監視キーワードや通知設定を変更可能

## 技術スタック

| コンポーネント | 技術 |
|---------------|------|
| 実行環境 | AWS Lambda |
| 言語 | Ruby 3.2+ |
| スクレイピング | Nokogiri |
| データベース | DynamoDB |
| 通知 | LINE Messaging API |
| インフラ管理 | AWS SAM |
| スケジューラ | Amazon EventBridge |

## アーキテクチャ

```
EventBridge (Schedule)
        │
        ▼
  ┌─────────────┐     ┌─────────────┐
  │   Scraper   │────▶│  DynamoDB   │
  │   Lambda    │     │  (Products) │
  └─────────────┘     └─────────────┘
        │                    │
        ▼                    │
  ┌─────────────┐           │
  │  Notifier   │◀──────────┘
  │   Lambda    │
  └──────┬──────┘
         │
         ▼
  ┌─────────────┐     ┌─────────────┐
  │ API Gateway │────▶│  DynamoDB   │
  │  (Webhook)  │     │   (Users)   │
  └─────────────┘     └─────────────┘
         │
         ▼
    LINE Platform
```

## セットアップ

### 前提条件

- Ruby 3.2+
- AWS CLI
- AWS SAM CLI
- LINE Developersアカウント

### インストール

```bash
# 依存関係のインストール
bundle install

# SAMビルド
sam build

# デプロイ（初回）
sam deploy --guided
```

### 環境変数

```bash
# .env.example をコピー
cp .env.example .env

# 以下の環境変数を設定
LINE_CHANNEL_SECRET=your_channel_secret
LINE_CHANNEL_ACCESS_TOKEN=your_access_token
AMAZON_ACCESS_KEY=your_amazon_key
AMAZON_SECRET_KEY=your_amazon_secret
RAKUTEN_APP_ID=your_rakuten_app_id
YAHOO_APP_ID=your_yahoo_app_id
```

## LINE Botコマンド

| コマンド | 説明 |
|---------|------|
| `設定` | 現在の設定を表示 |
| `通知ON` | 通知を有効化 |
| `通知OFF` | 通知を無効化 |
| `キーワード追加 <word>` | 監視キーワードを追加 |
| `キーワード削除 <word>` | 監視キーワードを削除 |
| `ヘルプ` | 使い方を表示 |

## 開発

```bash
# テスト実行
bundle exec rspec

# ローカルでLambda実行
sam local invoke ScraperFunction
```

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照してください。
