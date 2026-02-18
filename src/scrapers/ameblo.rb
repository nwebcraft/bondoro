# frozen_string_literal: true

require 'nokogiri'
require_relative 'base'

module Bondoro
  module Scrapers
    class Ameblo < Base
      SOURCE   = 'ameblo'
      BASE_URL = 'https://blogtag.ameba.jp'.freeze
      TAG_PATH = '/news/%s'.freeze

      def fetch
        results = []

        SEARCH_KEYWORDS.each do |keyword|
          items = fetch_by_tag(keyword)
          results.concat(items)
          sleep_between_requests(2)
        end

        results.uniq { |item| item[:url] }
      end

      private

      def fetch_by_tag(keyword)
        client = http_client(BASE_URL)
        path   = format(TAG_PATH, URI.encode_www_form_component(keyword))
        response = client.get(path)
        parse_html(response.body)
      rescue Faraday::Error => e
        log_error(e)
        []
      end

      def parse_html(html)
        doc = Nokogiri::HTML(html)
        doc.css('h2 a[href*="ameblo.jp"][href*="/entry-"]').filter_map do |a|
          url   = a['href']
          title = a.at_css('span')&.text&.strip
          next if url.nil? || title.nil? || title.empty?

          { title: title, url: url, price: nil, source: SOURCE }
        end
      end
    end
  end
end
