# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bondoro::Product do
  let(:db) { instance_double(Bondoro::DynamoDBClient) }

  before do
    allow(Bondoro::DynamoDBClient).to receive(:new).and_return(db)
  end

  describe '.find_or_create' do
    let(:url)    { 'https://item.rakuten.co.jp/shop/bonbon-drop-001' }
    let(:source) { 'rakuten' }
    let(:title)  { 'ボンボンドロップシール スイーツ柄' }
    let(:price)  { 980 }

    context '新規商品の場合' do
      before do
        allow(db).to receive(:get_item).and_return(nil)
        allow(db).to receive(:put_item)
      end

      it '新規フラグがtrueで返る' do
        result = described_class.find_or_create(url: url, source: source, title: title, price: price)
        expect(result[:new]).to be true
      end

      it 'DynamoDBにput_itemが呼ばれる' do
        described_class.find_or_create(url: url, source: source, title: title, price: price)
        expect(db).to have_received(:put_item).once
      end

      it 'notified_statusがfalseで保存される' do
        described_class.find_or_create(url: url, source: source, title: title, price: price)
        expect(db).to have_received(:put_item).with(
          table_name: anything,
          item: hash_including('notified_status' => 'false', 'notified' => false)
        )
      end
    end

    context '既存商品の場合' do
      let(:existing_item) do
        {
          'pk' => "PRODUCT##{Digest::SHA256.hexdigest(url)}",
          'sk' => "SOURCE##{source}",
          'url' => url, 'title' => title, 'price' => price,
          'source' => source, 'notified' => true,
          'notified_status' => 'true',
          'first_seen_at' => '2024-01-01T00:00:00+09:00',
          'last_seen_at' => '2024-01-01T00:00:00+09:00'
        }
      end

      before do
        allow(db).to receive(:get_item).and_return(existing_item)
        allow(db).to receive(:update_item)
      end

      it '新規フラグがfalseで返る' do
        result = described_class.find_or_create(url: url, source: source, title: title, price: price)
        expect(result[:new]).to be false
      end

      it 'last_seen_atのみ更新される' do
        described_class.find_or_create(url: url, source: source, title: title, price: price)
        expect(db).to have_received(:update_item).with(
          table_name: anything,
          pk: anything,
          sk: anything,
          updates: hash_including(:last_seen_at)
        )
      end
    end
  end

  describe '.unnotified' do
    let(:item) do
      {
        'pk' => 'PRODUCT#abc', 'sk' => 'SOURCE#rakuten',
        'url' => 'https://example.com', 'title' => 'テスト商品',
        'source' => 'rakuten', 'notified' => false,
        'notified_status' => 'false',
        'first_seen_at' => '2024-01-01T00:00:00+09:00',
        'last_seen_at' => '2024-01-01T00:00:00+09:00'
      }
    end

    before { allow(db).to receive(:query).and_return([item]) }

    it '未通知商品をProductオブジェクトで返す' do
      products = described_class.unnotified
      expect(products).to all(be_a(described_class))
      expect(products.first.notified).to be false
    end
  end

  describe '#mark_as_notified!' do
    let(:product) do
      described_class.new(
        'pk' => 'PRODUCT#abc', 'sk' => 'SOURCE#rakuten',
        'url' => 'https://example.com', 'title' => 'テスト',
        'source' => 'rakuten', 'notified' => false,
        'notified_status' => 'false',
        'first_seen_at' => '2024-01-01T00:00:00+09:00',
        'last_seen_at' => '2024-01-01T00:00:00+09:00'
      )
    end

    before { allow(db).to receive(:update_item) }

    it 'notifiedがtrueになる' do
      product.mark_as_notified!
      expect(product.notified).to be true
    end

    it 'DynamoDBのupdate_itemが呼ばれる' do
      product.mark_as_notified!
      expect(db).to have_received(:update_item).with(
        table_name: anything,
        pk: anything,
        sk: anything,
        updates: hash_including(notified: true, notified_status: 'true')
      )
    end
  end
end
