# Change: ボンボンドロップシール販売通知システムの構築

## Why

クーリア（Q-LiA）のボンボンドロップシール（BONBON DROP）は平成レトロブームにより入手困難になるほどの人気商品。
ファンが複数のECサイトやブログを手動でチェックする負担を軽減し、販売・入荷情報をリアルタイムでLINE通知することで、購入機会を逃さないようにしたい。

## What Changes

### 新規構築するシステム

1. **スクレイピングシステム**
   - 対象サイト: 楽天市場, Yahoo!ショッピング, アメブロ
   - 検索キーワード: 「ボンボンドロップ」「BONBON DROP」「クーリア シール」等
   - 取得頻度: 数時間ごと（低頻度）
   - 重複排除機能

2. **LINE通知システム**
   - LINE Messaging APIを使用
   - 友だち追加で自動登録
   - 新着情報のプッシュ通知

3. **ユーザー管理システム**
   - 友だち追加で自動登録、ブロックで無効化
   - キーワード・通知設定は管理者が管理

4. **データストレージ**
   - 商品情報の永続化
   - ユーザー設定の保存
   - 通知履歴の管理

## Impact

- Affected specs: 新規作成（scraping, notification, user-management）
- Affected code: 新規プロジェクト

## 技術スタック

| コンポーネント | 技術 | 理由 |
|---------------|------|------|
| 実行環境 | AWS Lambda | サーバーレス、コスト効率、スケーラブル |
| 言語 | Ruby 3.2+ | 開発者のスキルセット、Nokogiriの実績 |
| スクレイピング | Nokogiri + Ferrum | 静的/動的ページ両対応 |
| 通知 | LINE Messaging API | 日本での普及率、プッシュ通知対応 |
| データベース | DynamoDB | サーバーレス、スケーラブル、低コスト |
| スケジューラ | EventBridge | Lambda定期実行 |
| インフラ管理 | AWS SAM (Serverless Application Model) | Ruby Lambda対応、YAMLベースでシンプル |

### Lambda + Ruby について

- AWS Lambda Ruby 3.2 ランタイムがネイティブサポート（2023年〜）
- Cold Start: 約300-500ms（許容範囲）
- Nokogiriはネイティブ拡張だがLambda Layerで対応可能

### インフラ管理: AWS SAM を選択

**SAMを選ぶ理由:**
- Ruby Lambdaとの相性が良い
- `template.yaml` でシンプルに定義
- `sam build` でネイティブ拡張を含むGemを自動ビルド
- `sam deploy` でCloudFormationスタックとしてデプロイ
- ローカルテスト可能（`sam local invoke`）

**代替案:**
- Terraform: より汎用的だが学習コストが高い
- Serverless Framework: Node.js中心のエコシステム
- AWS CDK (Ruby): 存在するが成熟度が低い

## スコープ外（MVP後に検討）

- Amazon PA-API連携（アソシエイト審査が必要）
- メール通知
- Web管理画面
- 公式サイトからの情報取得（API連携など）
- 価格変動アラート
