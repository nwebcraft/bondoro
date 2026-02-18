# frozen_string_literal: true

require 'time'
require_relative '../lib/dynamodb_client'

module Bondoro
  class User
    TABLE_NAME = ENV.fetch('DYNAMODB_USERS_TABLE', 'bondoro-users')

    DEFAULT_KEYWORDS = ['ボンボンドロップ', 'BONBON DROP'].freeze
    DEFAULT_SOURCES  = %w[rakuten yahoo ameblo].freeze

    attr_reader :pk, :sk, :line_user_id, :display_name,
                :notification_enabled, :keywords, :sources,
                :created_at, :updated_at

    def initialize(attrs)
      @pk                   = attrs['pk']
      @sk                   = attrs['sk']
      @line_user_id         = attrs['line_user_id']
      @display_name         = attrs['display_name']
      @notification_enabled = attrs['notification_enabled'] != false
      @keywords             = attrs['keywords'] || DEFAULT_KEYWORDS.dup
      @sources              = attrs['sources']  || DEFAULT_SOURCES.dup
      @created_at           = attrs['created_at']
      @updated_at           = attrs['updated_at']
    end

    # 友だち追加時に登録、既存の場合は通知を有効化して返す
    def self.find_or_create(line_user_id:, display_name: nil)
      db = DynamoDBClient.new
      pk = "USER##{line_user_id}"
      sk = 'PROFILE'

      existing = db.get_item(table_name: TABLE_NAME, pk: pk, sk: sk)

      if existing
        # ブロック解除などで再登録の場合は通知を有効化
        unless existing['notification_enabled']
          db.update_item(
            table_name: TABLE_NAME,
            pk: pk,
            sk: sk,
            updates: { notification_enabled: true, updated_at: Time.now.iso8601 }
          )
          existing['notification_enabled'] = true
        end
        return new(existing)
      end

      now = Time.now.iso8601
      item = {
        'pk'                   => pk,
        'sk'                   => sk,
        'line_user_id'         => line_user_id,
        'display_name'         => display_name,
        'notification_enabled' => true,
        'keywords'             => DEFAULT_KEYWORDS.dup,
        'sources'              => DEFAULT_SOURCES.dup,
        'created_at'           => now,
        'updated_at'           => now
      }.compact

      db.put_item(table_name: TABLE_NAME, item: item)
      new(item)
    end

    # 通知が有効な全ユーザーを取得
    def self.notifiable
      db = DynamoDBClient.new
      items = db.scan(
        table_name: TABLE_NAME,
        filter_expression: 'notification_enabled = :enabled AND sk = :sk',
        expression_attribute_values: { ':enabled' => true, ':sk' => 'PROFILE' }
      )
      items.map { |item| new(item) }
    end

    def self.find(line_user_id)
      db = DynamoDBClient.new
      item = db.get_item(
        table_name: TABLE_NAME,
        pk: "USER##{line_user_id}",
        sk: 'PROFILE'
      )
      item ? new(item) : nil
    end

    def enable_notification!
      update(notification_enabled: true)
      @notification_enabled = true
    end

    def disable_notification!
      update(notification_enabled: false)
      @notification_enabled = false
    end

    def add_keyword!(word)
      return if keywords.include?(word)

      new_keywords = keywords + [word]
      update(keywords: new_keywords)
      @keywords = new_keywords
    end

    def remove_keyword!(word)
      new_keywords = keywords - [word]
      update(keywords: new_keywords)
      @keywords = new_keywords
    end

    def to_h
      {
        line_user_id: line_user_id,
        display_name: display_name,
        notification_enabled: notification_enabled,
        keywords: keywords,
        sources: sources,
        created_at: created_at,
        updated_at: updated_at
      }
    end

    private

    def update(attrs)
      db = DynamoDBClient.new
      db.update_item(
        table_name: TABLE_NAME,
        pk: pk,
        sk: sk,
        updates: attrs.merge(updated_at: Time.now.iso8601)
      )
    end
  end
end
