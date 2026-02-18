# frozen_string_literal: true

require_relative 'base'

module Bondoro
  module Scrapers
    class Rakuten < Base
      BASE_URL     = 'https://app.rakuten.co.jp'
      ENDPOINT     = '/services/api/IchibaItem/Search/20170706'
      SOURCE       = 'rakuten'
      MAX_PER_PAGE = 30

      def initialize
        @app_id = ENV.fetch('RAKUTEN_APP_ID')
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
          applicationId: @app_id,
          keyword: keyword,
          hits: MAX_PER_PAGE,
          sort: '-updateTimestamp'
        })

        return [] unless data&.dig('Items')

        data['Items'].map { |wrapper| parse_item(wrapper['Item']) }
      rescue StandardError => e
        log_error(e)
        []
      end

      def parse_item(item)
        {
          title:  item['itemName'],
          url:    item['itemUrl'],
          price:  item['itemPrice'],
          source: SOURCE
        }
      end
    end
  end
end
