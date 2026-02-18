# frozen_string_literal: true

require 'line/bot'

module Bondoro
  module Services
    class LineClient
      MAX_RETRIES = 3
      RETRY_BASE_SECONDS = 2

      def initialize
        @client = Line::Bot::Client.new do |config|
          config.channel_secret       = ENV.fetch('LINE_CHANNEL_SECRET')
          config.channel_token        = ENV.fetch('LINE_CHANNEL_ACCESS_TOKEN')
        end
      end

      # 単一ユーザーへプッシュ通知
      def push(to:, messages:)
        with_retry do
          response = @client.push_message(to, messages)
          handle_response(response, to)
        end
      end

      # 複数ユーザーへ一括プッシュ（LINE API上限: 500人）
      def multicast(to:, messages:)
        to.each_slice(500) do |group|
          with_retry do
            response = @client.multicast(group, messages)
            handle_response(response, group)
          end
        end
      end

      private

      def handle_response(response, to)
        return true if response.is_a?(Net::HTTPSuccess)

        body = response.body rescue nil
        warn "[LineClient] Failed to send to #{to}: #{response.code} #{body}"

        raise BlockedError, to if response.code == '400' && body&.include?('Invalid reply token')

        false
      end

      def with_retry
        retries = 0
        begin
          yield
        rescue BlockedError
          raise
        rescue StandardError => e
          retries += 1
          if retries <= MAX_RETRIES
            sleep(RETRY_BASE_SECONDS**retries)
            retry
          end
          warn "[LineClient] Max retries exceeded: #{e.message}"
          false
        end
      end

      class BlockedError < StandardError
        def initialize(user_id)
          super("User #{user_id} has blocked the bot")
        end
      end
    end
  end
end
