# frozen_string_literal: true

require_relative '../models/product'

module Bondoro
  module Services
    class Deduplicator
      # スクレイパーの結果を受け取り、新着のみ返す
      # @param items [Array<Hash>] [{ title:, url:, price:, source: }, ...]
      # @return [Array<Product>] 新規登録された商品のみ
      def self.process(items)
        new_products = []

        items.each do |item|
          result = Product.find_or_create(
            url:    item[:url],
            source: item[:source],
            title:  item[:title],
            price:  item[:price]
          )
          new_products << result[:product] if result[:new]
        end

        new_products
      end
    end
  end
end
