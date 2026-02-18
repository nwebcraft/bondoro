# frozen_string_literal: true

require 'dotenv'
Dotenv.load

require 'aws-sdk-sqs'
require 'json'
require_relative '../scrapers/rakuten'
require_relative '../scrapers/yahoo'
require_relative '../scrapers/ameblo'
require_relative '../services/deduplicator'

module Bondoro
  module Handlers
    class Scraper
      SCRAPERS = [
        Scrapers::Rakuten,
        Scrapers::Yahoo,
        Scrapers::Ameblo
      ].freeze

      def self.handler(event:, context:)
        puts 'Scraper Lambda started'
        new.run
        { statusCode: 200, body: 'OK' }
      rescue StandardError => e
        warn "Scraper failed: #{e.message}\n#{e.backtrace.join("\n")}"
        { statusCode: 500, body: e.message }
      end

      def run
        all_items = collect_items
        puts "Collected #{all_items.size} items total"

        new_products = Services::Deduplicator.process(all_items)
        puts "New products: #{new_products.size}"

        notify_if_needed(new_products)
      end

      private

      def collect_items
        SCRAPERS.flat_map do |scraper_class|
          puts "Running #{scraper_class.name}..."
          scraper_class.new.fetch
        rescue StandardError => e
          warn "#{scraper_class.name} failed: #{e.message}"
          []
        end
      end

      def notify_if_needed(new_products)
        return if new_products.empty?

        puts "Sending notification trigger for #{new_products.size} new products"
        sqs = Aws::SQS::Client.new(region: ENV.fetch('AWS_REGION', 'ap-northeast-1'))
        queue_url = ENV.fetch('NOTIFICATION_QUEUE_URL')

        sqs.send_message(
          queue_url: queue_url,
          message_body: JSON.generate({ new_product_count: new_products.size })
        )
      end
    end
  end
end

def handler(event:, context:)
  Bondoro::Handlers::Scraper.handler(event: event, context: context)
end
