# frozen_string_literal: true

require 'dotenv'
Dotenv.load

require_relative '../services/notifier'

module Bondoro
  module Handlers
    class Notifier
      def self.handler(event:, context:)
        puts "Notifier Lambda started. Records: #{event['Records']&.size}"
        Services::Notifier.run
        { statusCode: 200, body: 'OK' }
      rescue StandardError => e
        warn "Notifier failed: #{e.message}\n#{e.backtrace.join("\n")}"
        { statusCode: 500, body: e.message }
      end
    end
  end
end

def handler(event:, context:)
  Bondoro::Handlers::Notifier.handler(event: event, context: context)
end
