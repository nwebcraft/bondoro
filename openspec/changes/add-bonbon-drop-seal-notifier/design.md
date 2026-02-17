# Design: ボンボンドロップシール販売通知システム

## Context

### 背景
- クーリア（Q-LiA）のボンボンドロップシールは平成レトロブームで大人気
- 複数ECサイト（楽天, Yahoo!）とブログ（アメブロ）を監視する必要がある
- ユーザーが手動でチェックする負担を軽減したい

### 制約
- サーバーレスアーキテクチャ（AWS Lambda）
- Ruby 3.2+
- 初期ユーザー数: 〜50人程度、将来的にスケール想定
- 取得頻度: 数時間ごと（低頻度）

### ステークホルダー
- エンドユーザー: ボンボンドロップシール収集者
- 運営者: システム管理者（開発者）

## Goals / Non-Goals

### Goals
- 楽天、Yahoo! + アメブロから「ボンボンドロップ」関連商品情報を自動収集
- 新着情報をLINEでプッシュ通知（1通に集約）
- ユーザーが通知設定をカスタマイズ可能
- 重複通知の排除
- 低コストで運用可能なサーバーレス構成

### Non-Goals
- リアルタイム通知（秒単位）
- 自動購入機能
- 価格比較・最安値通知
- Web管理画面（MVP外）
- メール通知（MVP外）
- メルカリ対応（対象外）
- Amazon PA-API連携（MVP外、アソシエイト審査が必要）

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Cloud                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │  EventBridge │────▶│   Scraper    │────▶│  DynamoDB    │    │
│  │  (Schedule)  │     │   Lambda     │     │  (Products)  │    │
│  └──────────────┘     └──────────────┘     └──────────────┘    │
│                              │                    │              │
│                              │ 新着検出           │              │
│                              ▼                    │              │
│                       ┌──────────────┐           │              │
│                       │  Notifier    │◀──────────┘              │
│                       │   Lambda     │                          │
│                       └──────┬───────┘                          │
│                              │                                   │
│  ┌──────────────┐           │           ┌──────────────┐       │
│  │  API Gateway │◀──────────┼──────────▶│  DynamoDB    │       │
│  │  (Webhook)   │           │           │   (Users)    │       │
│  └──────┬───────┘           │           └──────────────┘       │
│         │                   │                                   │
└─────────┼───────────────────┼───────────────────────────────────┘
          │                   │
          ▼                   ▼
    ┌──────────┐        ┌──────────┐
    │   LINE   │        │   LINE   │
    │  Webhook │        │   Push   │
    └──────────┘        └──────────┘
```

## Decisions

### Decision 1: Lambda構成（機能別に分割）

| Lambda | 役割 | トリガー |
|--------|------|---------|
| `scraper` | ECサイト・アメブロからの情報収集 | EventBridge (スケジュール) |
| `notifier` | LINE通知送信 | DynamoDB Streams または SQS |
| `webhook` | LINE Webhookハンドラ | API Gateway |

**理由:**
- 責務分離によりデバッグが容易
- スクレイピングのタイムアウトが通知に影響しない
- 個別にスケール可能

### Decision 2: スクレイピング対象サイトごとの戦略

| サイト | 方式 | 理由 |
|--------|------|------|
| 楽天 | 楽天商品検索API | 公式API、無料枠あり |
| Yahoo! | Yahoo!ショッピングAPI | 公式API |
| アメブロ | RSSフィード + スクレイピング (Nokogiri) | MVP対象 |

> **Note:** Amazon PA-APIはアソシエイト審査が必要なため、MVP後に追加予定。

**注意:**
- 各サイトの利用規約を遵守
- スクレイピング頻度を適切に制限（レートリミット）
- User-Agentを適切に設定

### Decision 3: Productsテーブル設計と重複排除ロジック

#### スキーマ

```ruby
# DynamoDB Products テーブル
{
  pk: "PRODUCT#<url_hash>",     # パーティションキー
  sk: "SOURCE#<source_name>",   # ソートキー
  url: "https://...",
  title: "ボンボンドロップシール...",
  price: 1200,
  source: "rakuten",
  first_seen_at: "2024-01-01T00:00:00Z",
  last_seen_at: "2024-01-02T00:00:00Z",
  notified: true
}
```

#### キー設計の解説

**pk (パーティションキー): `PRODUCT#<url_hash>`**
- 商品URLのSHA256ハッシュを使用
- URLそのものは長すぎるため、ハッシュ化して一意性を保証
- 例: `PRODUCT#a1b2c3d4...`（64文字の16進数）

**sk (ソートキー): `SOURCE#<source_name>`**
- 同一商品が複数ソースに存在する場合を想定
- 例: `SOURCE#rakuten`, `SOURCE#yahoo`
- pk + sk の組み合わせでユニークに

#### 重複排除ロジック

```ruby
def find_or_create_product(url:, source:, title:, price:)
  url_hash = Digest::SHA256.hexdigest(url)
  pk = "PRODUCT##{url_hash}"
  sk = "SOURCE##{source}"

  existing = dynamodb.get_item(pk: pk, sk: sk)

  if existing
    # 既存: last_seen_at を更新、notified は変更しない
    dynamodb.update_item(pk: pk, sk: sk, last_seen_at: Time.now.iso8601)
    return { new: false, product: existing }
  else
    # 新規: 作成して notified = false
    product = {
      pk: pk, sk: sk,
      url: url, title: title, price: price, source: source,
      first_seen_at: Time.now.iso8601,
      last_seen_at: Time.now.iso8601,
      notified: false
    }
    dynamodb.put_item(product)
    return { new: true, product: product }
  end
end
```

**ポイント:**
- `notified: false` の商品だけを通知対象として抽出
- 通知後に `notified: true` に更新
- `first_seen_at` で初回発見日時、`last_seen_at` で最終確認日時を記録

#### GSI（グローバルセカンダリインデックス）

通知対象の商品を効率的に取得するために GSI を作成:

```yaml
GSI1:
  pk: notified (BOOL → 文字列化 "false" / "true")
  sk: first_seen_at
```

これにより `notified = false` の商品を `first_seen_at` 順で取得可能。

### Decision 4: Usersテーブル設計

#### スキーマ

```ruby
# DynamoDB Users テーブル
{
  pk: "USER#<line_user_id>",
  sk: "PROFILE",
  line_user_id: "U1234567890abcdef",
  display_name: "ユーザー名",
  notification_enabled: true,
  keywords: ["ボンボンドロップ", "BONBON DROP"],
  sources: ["rakuten", "yahoo", "ameblo"],
  created_at: "2024-01-01T00:00:00Z",
  updated_at: "2024-01-02T00:00:00Z"
}
```

#### キー設計の解説

**pk (パーティションキー): `USER#<line_user_id>`**
- LINE User IDをそのまま使用（一意性が保証されている）
- プレフィックス `USER#` を付けることで、将来的に同一テーブルで他エンティティ（例: `NOTIFICATION_LOG#`）を管理可能に
- 例: `USER#U1234567890abcdef`

**sk (ソートキー): `PROFILE`**
- 現在は単一レコードだが、将来的に `SETTINGS`, `HISTORY` など追加可能
- 例: `USER#U123` + `PROFILE` → ユーザープロファイル
- 例: `USER#U123` + `HISTORY#2024-01-01` → 通知履歴（将来拡張）

#### 属性の解説

| 属性 | 型 | 説明 |
|------|------|------|
| `line_user_id` | String | LINE APIから取得するユーザーID |
| `display_name` | String | LINEプロフィール名（表示用） |
| `notification_enabled` | Boolean | 通知ON/OFF |
| `keywords` | List<String> | 監視キーワード（デフォルト: ボンボンドロップ, BONBON DROP） |
| `sources` | List<String> | 監視対象ソース（デフォルト: 全て） |
| `created_at` | String (ISO8601) | 登録日時 |
| `updated_at` | String (ISO8601) | 最終更新日時 |

#### Single Table Design について

DynamoDBでは「Single Table Design」パターンが推奨される場合がありますが、本プロジェクトでは:
- テーブル数が少ない（Products, Users の2つ）
- アクセスパターンがシンプル
- 管理のしやすさを優先

のため、**テーブル分離設計**を採用します。

### Decision 5: LINE Bot インタラクション設計

**友だち追加時:**
1. ウェルカムメッセージ送信
2. デフォルト設定で自動登録
3. 設定方法の案内

**コマンド:**
| コマンド | 動作 |
|---------|------|
| `設定` | 現在の設定を表示 |
| `通知ON` / `通知OFF` | 通知の有効/無効切替 |
| `キーワード追加 <word>` | 監視キーワード追加 |
| `キーワード削除 <word>` | 監視キーワード削除 |
| `ヘルプ` | 使い方を表示 |

**通知メッセージフォーマット（1通に集約）:**
```
🆕 新着情報！

【楽天市場】
ボンボンドロップシール △△セット
💰 ¥980
🔗 https://item.rakuten.co.jp/...

【アメブロ】
ボンボンドロップシール入荷情報！
🔗 https://ameblo.jp/...

---
全2件の新着がありました
```

## Risks / Trade-offs

### Risk 1: スクレイピングのブロック
- **リスク:** ECサイトからのアクセスブロック
- **緩和策:**
  - 公式APIがあるサイトは必ずAPI使用
  - スクレイピング頻度を低く保つ（数時間ごと）
  - 適切なUser-Agent設定
  - IPローテーションは行わない（規約違反リスク）

### Risk 2: Lambda Cold Start
- **リスク:** Ruby Lambdaの起動が遅い
- **緩和策:**
  - Provisioned Concurrencyは不要（低頻度実行のため）
  - 起動時間は数百msで許容範囲

### Risk 3: LINE API制限
- **リスク:** プッシュメッセージの送信制限
- **緩和策:**
  - 無料プランでも月1000通まで可能
  - ユーザー数増加時は有料プラン移行

### Risk 4: Nokogiriネイティブ拡張
- **リスク:** Lambda環境でのビルド問題
- **緩和策:**
  - AWS SAMでDockerビルドを使用
  - Lambda Layerとして事前ビルド

## Migration Plan

N/A（新規プロジェクト）

## Open Questions

1. **Q: ブログ監視の範囲拡大**
   - MVP後、アメブロ以外のブログサービスを追加するか？
   - RSS対応していないブログはどう扱うか？

## ディレクトリ構成

```
bondoro/
├── template.yaml           # AWS SAM テンプレート
├── Gemfile
├── Gemfile.lock
├── src/
│   ├── handlers/
│   │   ├── scraper.rb      # スクレイピングLambda
│   │   ├── notifier.rb     # 通知Lambda
│   │   └── webhook.rb      # LINE Webhook Lambda
│   ├── scrapers/
│   │   ├── base.rb
│   │   ├── rakuten.rb
│   │   ├── yahoo.rb
│   │   └── ameblo.rb       # アメブロスクレイパー
│   ├── models/
│   │   ├── product.rb
│   │   └── user.rb
│   ├── services/
│   │   ├── line_client.rb
│   │   ├── deduplicator.rb
│   │   └── notifier.rb
│   └── lib/
│       └── dynamodb_client.rb
├── spec/                   # RSpec テスト
│   ├── handlers/
│   ├── scrapers/
│   └── services/
└── openspec/               # OpenSpec仕様
```
