# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bondoro::Services::MessageFormatter do
  def build_product(attrs = {})
    Bondoro::Product.new({
      'pk' => 'PRODUCT#abc', 'sk' => 'SOURCE#rakuten',
      'url' => 'https://example.com', 'title' => 'ボンボンドロップシール',
      'source' => 'rakuten', 'price' => 980, 'notified' => false,
      'notified_status' => 'false',
      'first_seen_at' => '2024-01-01T00:00:00+09:00',
      'last_seen_at' => '2024-01-01T00:00:00+09:00'
    }.merge(attrs.transform_keys(&:to_s)))
  end

  describe '.build' do
    context '1件の新着' do
      let(:products) { [build_product] }

      it 'テキストメッセージを返す' do
        messages = described_class.build(products)
        expect(messages.first[:type]).to eq('text')
      end

      it '新着情報のヘッダーが含まれる' do
        messages = described_class.build(products)
        expect(messages.first[:text]).to include('新着情報')
      end

      it '商品タイトルが含まれる' do
        messages = described_class.build(products)
        expect(messages.first[:text]).to include('ボンボンドロップシール')
      end

      it '価格が含まれる' do
        messages = described_class.build(products)
        expect(messages.first[:text]).to include('¥980')
      end
    end

    context '10件を超える新着' do
      let(:products) do
        12.times.map { |i| build_product('url' => "https://example.com/#{i}") }
      end

      it '上位10件のみ表示' do
        messages = described_class.build(products)
        expect(messages.first[:text]).to include('他2件あります')
      end
    end

    context '価格なしの商品（アメブロ等）' do
      let(:products) { [build_product('price' => nil, 'source' => 'ameblo')] }

      it '価格行が表示されない' do
        messages = described_class.build(products)
        expect(messages.first[:text]).not_to include('¥')
      end

      it 'アメブロのラベルが表示される' do
        messages = described_class.build(products)
        expect(messages.first[:text]).to include('アメブロ')
      end
    end
  end
end
