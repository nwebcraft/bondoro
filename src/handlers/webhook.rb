# frozen_string_literal: true

require 'dotenv'
Dotenv.load

require 'line/bot'
require 'json'
require_relative '../models/user'

module Bondoro
  module Handlers
    class Webhook
      def self.handler(event:, context:)
        new(event).process
      rescue StandardError => e
        warn "Webhook failed: #{e.message}\n#{e.backtrace.join("\n")}"
        { statusCode: 500, body: e.message }
      end

      def initialize(event)
        @event = event
        @line_client_raw = Line::Bot::Client.new do |config|
          config.channel_secret = ENV.fetch('LINE_CHANNEL_SECRET')
          config.channel_token  = ENV.fetch('LINE_CHANNEL_ACCESS_TOKEN')
        end
      end

      def process
        body      = @event['body'] || ''
        signature = @event.dig('headers', 'x-line-signature') ||
                    @event.dig('headers', 'X-Line-Signature') || ''

        unless @line_client_raw.validate_signature(body, signature)
          warn 'Invalid LINE signature'
          return { statusCode: 401, body: 'Unauthorized' }
        end

        parsed = JSON.parse(body)
        parsed['events'].each { |line_event| handle_event(line_event) }

        { statusCode: 200, body: 'OK' }
      end

      private

      def handle_event(line_event)
        case line_event['type']
        when 'follow'
          handle_follow(line_event)
        when 'unfollow'
          handle_unfollow(line_event)
        end
      end

      def handle_follow(line_event)
        user_id      = line_event.dig('source', 'userId')
        profile      = fetch_profile(user_id)
        display_name = profile&.dig('displayName')

        User.find_or_create(line_user_id: user_id, display_name: display_name)
        puts "New follower: #{user_id} (#{display_name})"
      end

      def handle_unfollow(line_event)
        user_id = line_event.dig('source', 'userId')
        user    = User.find(user_id)
        user&.disable_notification!
        puts "Unfollowed: #{user_id}"
      end

      def fetch_profile(user_id)
        response = @line_client_raw.get_profile(user_id)
        return nil unless response.is_a?(Net::HTTPSuccess)

        JSON.parse(response.body)
      rescue StandardError
        nil
      end
    end
  end
end

def handler(event:, context:)
  Bondoro::Handlers::Webhook.handler(event: event, context: context)
end
