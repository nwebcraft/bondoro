# frozen_string_literal: true

require 'dotenv'
Dotenv.load

require 'line/bot'
require 'json'
require_relative '../models/user'
require_relative '../services/line_client'
require_relative '../services/command_parser'
require_relative '../services/reply_builder'

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
        @line_client = Services::LineClient.new
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
        when 'message'
          handle_message(line_event) if line_event.dig('message', 'type') == 'text'
        when 'unfollow'
          handle_unfollow(line_event)
        end
      end

      def handle_follow(line_event)
        user_id      = line_event.dig('source', 'userId')
        reply_token  = line_event['replyToken']
        profile      = fetch_profile(user_id)
        display_name = profile&.dig('displayName')

        User.find_or_create(line_user_id: user_id, display_name: display_name)
        puts "New follower: #{user_id} (#{display_name})"

        reply(reply_token, Services::ReplyBuilder.welcome)
      end

      def handle_message(line_event)
        user_id     = line_event.dig('source', 'userId')
        reply_token = line_event['replyToken']
        text        = line_event.dig('message', 'text').to_s

        user = User.find(user_id)
        unless user
          user = User.find_or_create(line_user_id: user_id)
        end

        result  = Services::CommandParser.parse(text)
        messages = dispatch(result, user)
        reply(reply_token, messages)
      end

      def handle_unfollow(line_event)
        user_id = line_event.dig('source', 'userId')
        user    = User.find(user_id)
        user&.disable_notification!
        puts "Unfollowed: #{user_id}"
      end

      def dispatch(result, user)
        case result.command
        when :settings
          Services::ReplyBuilder.settings(user)
        when :notification_on
          user.enable_notification!
          Services::ReplyBuilder.notification_on
        when :notification_off
          user.disable_notification!
          Services::ReplyBuilder.notification_off
        when :add_keyword
          user.add_keyword!(result.args)
          Services::ReplyBuilder.keyword_added(result.args)
        when :remove_keyword
          if user.keywords.include?(result.args)
            user.remove_keyword!(result.args)
            Services::ReplyBuilder.keyword_removed(result.args)
          else
            Services::ReplyBuilder.keyword_not_found(result.args)
          end
        when :help
          Services::ReplyBuilder.help
        else
          Services::ReplyBuilder.unknown
        end
      end

      def reply(reply_token, messages)
        @line_client_raw.reply_message(reply_token, messages)
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
