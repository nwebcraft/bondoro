# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bondoro::Scrapers::Rakuten do
  subject(:scraper) { described_class.new }

  before do
    stub_const('ENV', ENV.to_h.merge('RAKUTEN_APP_ID' => 'test_app_id', 'RAKUTEN_ACCESS_KEY' => 'test_access_key'))
  end

  describe '#fetch' do
    let(:api_response) do
      {
        'Items' => [
          {
            'Item' => {
              'itemName' => 'ボンボンドロップシール スイーツ柄',
              'itemUrl'  => 'https://item.rakuten.co.jp/shop/bonbon-001/',
              'itemPrice' => 980
            }
          },
          {
            'Item' => {
              'itemName' => 'BONBON DROP シール フルーツ',
              'itemUrl'  => 'https://item.rakuten.co.jp/shop/bonbon-002/',
              'itemPrice' => 1200
            }
          }
        ]
      }.to_json
    end

    before do
      stub_request(:get, /openapi\.rakuten\.co\.jp/)
        .to_return(status: 200, body: api_response, headers: { 'Content-Type' => 'application/json' })
    end

    it '商品リストを返す' do
      results = scraper.fetch
      expect(results).not_to be_empty
    end

    it 'sourceがrakutenになっている' do
      results = scraper.fetch
      expect(results).to all(include(source: 'rakuten'))
    end

    it 'title, url, priceが含まれる' do
      results = scraper.fetch
      expect(results.first).to include(:title, :url, :price)
    end

    it 'URLの重複が排除される' do
      results = scraper.fetch
      urls = results.map { |r| r[:url] }
      expect(urls).to eq(urls.uniq)
    end
  end

  describe '#fetch APIエラーの場合' do
    before do
      stub_request(:get, /openapi\.rakuten\.co\.jp/).to_return(status: 500)
    end

    it '空配列を返す' do
      results = scraper.fetch
      expect(results).to eq([])
    end
  end
end
