# frozen_string_literal: true

require_relative 'base'

module Bondoro
  module Scrapers
    class Rakuten < Base
      BASE_URL     = 'https://openapi.rakuten.co.jp'
      ENDPOINT     = '/ichibams/api/IchibaItem/Search/20220601'
      SOURCE       = 'rakuten'
      MAX_PER_PAGE = 30

      def initialize
        @app_id     = ENV.fetch('RAKUTEN_APP_ID')
        @access_key = ENV.fetch('RAKUTEN_ACCESS_KEY')
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

      def http_client(base_url)
        Faraday.new(url: base_url) do |f|
          f.headers['User-Agent'] = USER_AGENT
          f.headers['Origin']     = 'https://github.com'
          f.headers['Referer']    = 'https://github.com/'
          f.response :raise_error
          f.adapter Faraday.default_adapter
        end
      end

      def search(keyword)
        client = http_client(BASE_URL)
        data = get(client, ENDPOINT, {
          applicationId: @app_id,
          accessKey:     @access_key,
          keyword:       keyword,
          hits:          MAX_PER_PAGE,
          sort:          '-updateTimestamp'
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
