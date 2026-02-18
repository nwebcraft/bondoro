# frozen_string_literal: true

module Bondoro
  module Services
    class MessageFormatter
      MAX_ITEMS = 10

      SOURCE_LABELS = {
        'rakuten' => '楽天市場',
        'yahoo'   => 'Yahoo!ショッピング',
        'ameblo'  => 'アメブロ'
      }.freeze

      # 新着商品リストを1通のLINEメッセージに整形
      # @param products [Array<Product>]
      # @return [Array<Hash>] LINE messages array
      def self.build(products)
        new(products).build
      end

      def initialize(products)
        @products = products
      end

      def build
        display_products = @products.first(MAX_ITEMS)
        remaining = @products.size - display_products.size

        text = build_text(display_products, remaining)
        [{ type: 'text', text: text }]
      end

      private

      def build_text(products, remaining)
        lines = ["🆕 新着情報！\n"]

        products.group_by(&:source).each do |source, items|
          label = SOURCE_LABELS.fetch(source, source)
          lines << "【#{label}】"
          items.each do |product|
            lines << product.title.to_s
            lines << "💰 ¥#{product.price}" if product.price
            lines << "🔗 #{product.url}"
            lines << ''
          end
        end

        lines << '---'
        if remaining > 0
          lines << "全#{@products.size}件の新着（他#{remaining}件あります）"
        else
          lines << "全#{@products.size}件の新着がありました"
        end

        lines.join("\n").strip
      end
    end
  end
end
