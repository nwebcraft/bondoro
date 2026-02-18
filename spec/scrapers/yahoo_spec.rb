# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bondoro::Scrapers::Yahoo do
  subject(:scraper) { described_class.new }

  before do
    stub_const('ENV', ENV.to_h.merge('YAHOO_APP_ID' => 'test_app_id'))
  end

  describe '#fetch' do
    let(:api_response) do
      {
        'hits' => [
          {
            'name'  => 'ボンボンドロップシール アニマル柄',
            'url'   => 'https://shopping.yahoo.co.jp/product/bonbon-001',
            'price' => 880
          }
        ]
      }.to_json
    end

    before do
      stub_request(:get, /shopping\.yahooapis\.jp/)
        .to_return(status: 200, body: api_response, headers: { 'Content-Type' => 'application/json' })
    end

    it '商品リストを返す' do
      results = scraper.fetch
      expect(results).not_to be_empty
    end

    it 'sourceがyahooになっている' do
      results = scraper.fetch
      expect(results).to all(include(source: 'yahoo'))
    end

    it 'title, url, priceが含まれる' do
      results = scraper.fetch
      expect(results.first).to include(:title, :url, :price)
    end
  end

  describe '#fetch APIエラーの場合' do
    before do
      stub_request(:get, /shopping\.yahooapis\.jp/).to_return(status: 500)
    end

    it '空配列を返す' do
      results = scraper.fetch
      expect(results).to eq([])
    end
  end
end
