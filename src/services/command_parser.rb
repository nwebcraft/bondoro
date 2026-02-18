# frozen_string_literal: true

module Bondoro
  module Services
    class CommandParser
      COMMANDS = {
        /\A設定\z/           => :settings,
        /\A通知ON\z/i        => :notification_on,
        /\A通知OFF\z/i       => :notification_off,
        /\Aキーワード追加\s+(.+)\z/ => :add_keyword,
        /\Aキーワード削除\s+(.+)\z/ => :remove_keyword,
        /\Aヘルプ\z/         => :help
      }.freeze

      Result = Struct.new(:command, :args, keyword_init: true)

      def self.parse(text)
        text = text.to_s.strip

        COMMANDS.each do |pattern, command|
          match = text.match(pattern)
          next unless match

          args = match.captures.first
          return Result.new(command: command, args: args)
        end

        Result.new(command: :unknown, args: nil)
      end
    end
  end
end
