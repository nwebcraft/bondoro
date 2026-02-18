# frozen_string_literal: true

require 'rss'
require 'open-uri'
require 'nokogiri'
require_relative 'base'

module Bondoro
  module Scrapers
    class Ameblo < Base
      SOURCE = 'ameblo'

      # アメブロのキーワード検索RSS
      RSS_URL_TEMPLATE = 'https://blog.ameba.jp/ucs/keyword/srchkeyword.do?keyword=%s&orderby=1'.freeze

      def fetch
        results = []

        SEARCH_KEYWORDS.each do |keyword|
          items = fetch_rss(keyword)
          results.concat(items)
          sleep_between_requests(2)
        end

        results.uniq { |item| item[:url] }
      end

      private

      def fetch_rss(keyword)
        url = format(RSS_URL_TEMPLATE, URI.encode_www_form_component(keyword))
        feed = RSS::Parser.parse(URI.parse(url).open.read, false)
        return [] unless feed&.items

        feed.items.map { |item| parse_item(item) }
      rescue StandardError => e
        log_error(e)
        fetch_by_scraping(keyword)
      end

      def fetch_by_scraping(keyword)
        url = format(RSS_URL_TEMPLATE, URI.encode_www_form_component(keyword))
        html = URI.parse(url).open.read
        doc = Nokogiri::HTML(html)

        doc.css('item, .searchResult__item').map do |item|
          title_el = item.at_css('title, .searchResult__title')
          link_el  = item.at_css('link, a')
          next unless title_el && link_el

          {
            title:  title_el.text.strip,
            url:    link_el['href'] || link_el.text.strip,
            price:  nil,
            source: SOURCE
          }
        end.compact
      rescue StandardError => e
        log_error(e)
        []
      end

      def parse_item(item)
        {
          title:  item.title&.content || item.title.to_s,
          url:    item.link,
          price:  nil,
          source: SOURCE
        }
      end
    end
  end
end
