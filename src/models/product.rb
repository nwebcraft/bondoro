# frozen_string_literal: true

require 'digest'
require 'time'
require_relative '../lib/dynamodb_client'

module Bondoro
  class Product
    TABLE_NAME = ENV.fetch('DYNAMODB_PRODUCTS_TABLE', 'bondoro-products')
    NOTIFIED_INDEX = 'notified-index'

    attr_reader :pk, :sk, :url, :title, :price, :source,
                :first_seen_at, :last_seen_at, :notified

    def initialize(attrs)
      @pk           = attrs['pk']
      @sk           = attrs['sk']
      @url          = attrs['url']
      @title        = attrs['title']
      @price        = attrs['price']
      @source       = attrs['source']
      @first_seen_at = attrs['first_seen_at']
      @last_seen_at  = attrs['last_seen_at']
      @notified      = attrs['notified']
    end

    # 新規商品を登録、既存の場合は last_seen_at を更新
    # @return [Hash] { new: Boolean, product: Product }
    def self.find_or_create(url:, source:, title:, price: nil)
      db = DynamoDBClient.new
      url_hash = Digest::SHA256.hexdigest(url)
      pk = "PRODUCT##{url_hash}"
      sk = "SOURCE##{source}"

      existing = db.get_item(table_name: TABLE_NAME, pk: pk, sk: sk)

      if existing
        db.update_item(
          table_name: TABLE_NAME,
          pk: pk,
          sk: sk,
          updates: { last_seen_at: Time.now.iso8601 }
        )
        return { new: false, product: new(existing) }
      end

      now = Time.now.iso8601
      item = {
        'pk'            => pk,
        'sk'            => sk,
        'url'           => url,
        'title'         => title,
        'price'         => price,
        'source'        => source,
        'notified_status' => 'false',
        'first_seen_at' => now,
        'last_seen_at'  => now,
        'notified'      => false
      }.compact

      db.put_item(table_name: TABLE_NAME, item: item)
      { new: true, product: new(item) }
    end

    # 未通知の商品一覧を取得
    def self.unnotified(limit: 10)
      db = DynamoDBClient.new
      items = db.query(
        table_name: TABLE_NAME,
        index_name: NOTIFIED_INDEX,
        key_condition_expression: 'notified_status = :status',
        expression_attribute_values: { ':status' => 'false' },
        limit: limit
      )
      items.map { |item| new(item) }
    end

    # 通知済みにマーク
    def mark_as_notified!
      db = DynamoDBClient.new
      db.update_item(
        table_name: TABLE_NAME,
        pk: pk,
        sk: sk,
        updates: { notified: true, notified_status: 'true' }
      )
      @notified = true
    end

    def to_h
      {
        pk: pk, sk: sk, url: url, title: title,
        price: price, source: source,
        first_seen_at: first_seen_at, last_seen_at: last_seen_at,
        notified: notified
      }
    end
  end
end
