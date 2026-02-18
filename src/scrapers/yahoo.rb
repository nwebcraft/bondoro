# frozen_string_literal: true

require_relative 'base'

module Bondoro
  module Scrapers
    class Yahoo < Base
      BASE_URL = 'https://shopping.yahooapis.jp'
      ENDPOINT = '/ShoppingWebService/V3/itemSearch'
      SOURCE   = 'yahoo'
      MAX_RESULTS = 30

      def initialize
        @app_id = ENV.fetch('YAHOO_APP_ID')
      end

      def fetch
        results = []

        SEARCH_KEYWORDS.each do |keyword|
          items = search(keyword)
          results.concat(items)
          sleep_between_requests
        end

        results.uniq { |item| item[:url] }
      end

      private

      def search(keyword)
        client = http_client(BASE_URL)
        data = get(client, ENDPOINT, {
          appid:  @app_id,
          query:  keyword,
          results: MAX_RESULTS,
          sort:   '-score'
        })

        return [] unless data&.dig('hits')

        data['hits'].map { |item| parse_item(item) }
      rescue StandardError => e
        log_error(e)
        []
      end

      def parse_item(item)
        {
          title:  item.dig('name'),
          url:    item.dig('url'),
          price:  item.dig('price'),
          source: SOURCE
        }
      end
    end
  end
end
