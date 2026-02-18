# frozen_string_literal: true

module Bondoro
  module Services
    class ReplyBuilder
      SOURCE_LABELS = {
        'rakuten' => '楽天市場',
        'yahoo'   => 'Yahoo!ショッピング',
        'ameblo'  => 'アメブロ'
      }.freeze

      def self.welcome
        text = <<~TEXT.strip
          ボンボンドロップシール販売通知サービスへようこそ！🎉

          楽天市場・Yahoo!ショッピング・アメブロの新着情報を自動でお知らせします。

          以下のコマンドが使えます：
          ・設定 → 現在の設定を確認
          ・通知ON / 通知OFF → 通知の切替
          ・キーワード追加 ○○ → 監視キーワードを追加
          ・キーワード削除 ○○ → 監視キーワードを削除
          ・ヘルプ → コマンド一覧

          新着情報をお楽しみに！
        TEXT
        [{ type: 'text', text: text }]
      end

      def self.settings(user)
        status = user.notification_enabled ? 'ON' : 'OFF'
        keywords = user.keywords.join('、')
        sources = user.sources.map { |s| SOURCE_LABELS.fetch(s, s) }.join('、')

        text = <<~TEXT.strip
          【現在の設定】

          通知: #{status}
          監視キーワード: #{keywords}
          監視サイト: #{sources}
        TEXT
        [{ type: 'text', text: text }]
      end

      def self.notification_on
        [{ type: 'text', text: '通知をONにしました！新着情報をお届けします 🔔' }]
      end

      def self.notification_off
        [{ type: 'text', text: '通知をOFFにしました。再開するときは「通知ON」と送ってください 🔕' }]
      end

      def self.keyword_added(word)
        [{ type: 'text', text: "キーワード「#{word}」を追加しました ✅" }]
      end

      def self.keyword_removed(word)
        [{ type: 'text', text: "キーワード「#{word}」を削除しました ✅" }]
      end

      def self.keyword_not_found(word)
        [{ type: 'text', text: "キーワード「#{word}」は登録されていません" }]
      end

      def self.help
        text = <<~TEXT.strip
          【コマンド一覧】

          設定 → 現在の設定を確認
          通知ON → 通知を有効化
          通知OFF → 通知を無効化
          キーワード追加 ○○ → 監視キーワードを追加
          キーワード削除 ○○ → 監視キーワードを削除
          ヘルプ → このメッセージを表示
        TEXT
        [{ type: 'text', text: text }]
      end

      def self.unknown
        [{ type: 'text', text: 'コマンドが認識できませんでした。「ヘルプ」と送信してください' }]
      end
    end
  end
end
