# Bondoro - ボンボンドロップシール販売通知ツール

クーリア（Q-LiA）のボンボンドロップシール（BONBON DROP）の販売・入荷情報を自動収集し、LINEで通知するツールです。

## 概要

平成レトロブームで大人気のボンボンドロップシールは入手困難になることも。このツールは複数のECサイトとブログを定期的に監視し、新着情報をLINEでお知らせします。

## 機能

- **自動監視**: 楽天市場、Yahoo!ショッピング、アメブロを定期チェック
- **LINE通知**: 新着情報をLINEプッシュ通知でお届け
- **重複排除**: 同じ商品の重複通知を防止

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

# ビルド＆デプロイ（.env に環境変数を設定してから）
make deploy
```

### 環境変数

```bash
# .env.example をコピー
cp .env.example .env

# 以下の環境変数を設定
LINE_CHANNEL_SECRET=your_channel_secret
LINE_CHANNEL_ACCESS_TOKEN=your_access_token
RAKUTEN_APP_ID=your_rakuten_app_id
RAKUTEN_ACCESS_KEY=your_rakuten_access_key
YAHOO_APP_ID=your_yahoo_app_id
```

## 開発

```bash
# テスト実行
bundle exec rspec

# ローカルでLambda実行
sam local invoke ScraperFunction
```

## 免責事項

- 本ツールは商品の在庫状況や販売情報の通知を目的としたものであり、情報の正確性・即時性を保証するものではありません。
- 本ツールの利用により生じた損害（購入機会の逸失、誤情報に基づく購入等）について、開発者は一切の責任を負いません。
- 各ECサイト・ブログサービスの利用規約およびAPIの利用規約を遵守してご利用ください。利用規約の変更等により、本ツールの一部または全部の機能が利用できなくなる場合があります。
- 「ボンボンドロップシール」「BONBON DROP」はクーリア（Q-LiA）の商品名です。本プロジェクトはクーリア（Q-LiA）とは一切関係ありません。
- 各ECサイト名・サービス名は各社の商標または登録商標です。

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) を参照してください。
