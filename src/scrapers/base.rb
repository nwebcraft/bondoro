# frozen_string_literal: true

require 'faraday'
require 'json'

module Bondoro
  module Scrapers
    class Base
      SEARCH_KEYWORDS = ['ボンボンドロップ', 'BONBON DROP'].freeze
      USER_AGENT = 'Bondoro/1.0 (+https://github.com/nwebcraft/bondoro)'.freeze

      # サブクラスで実装する
      # @return [Array<Hash>] [{ title:, url:, price:, source: }, ...]
      def fetch
        raise NotImplementedError, "#{self.class}#fetch is not implemented"
      end

      private

      def http_client(base_url)
        Faraday.new(url: base_url) do |f|
          f.headers['User-Agent'] = USER_AGENT
          f.response :raise_error
          f.adapter Faraday.default_adapter
        end
      end

      def get(client, path, params = {})
        response = client.get(path, params)
        JSON.parse(response.body)
      rescue Faraday::Error => e
        log_error(e)
        nil
      end

      def log_error(error)
        warn "[#{self.class}] Error: #{error.message}"
      end

      def sleep_between_requests(seconds = 1)
        sleep(seconds)
      end
    end
  end
end
