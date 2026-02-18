# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bondoro::Scrapers::Ameblo do
  subject(:scraper) { described_class.new }

  let(:html_body) do
    <<~HTML
      <html><body>
        <ul>
          <li>
            <h2><a href="https://ameblo.jp/shop-example/entry-001.html" rel="noopener">
              <span>ボンボンドロップシール入荷しました！</span>
            </a></h2>
          </li>
          <li>
            <h2><a href="https://ameblo.jp/shop-example/entry-002.html" rel="noopener">
              <span>BONBON DROP 新作が届いた</span>
            </a></h2>
          </li>
        </ul>
      </body></html>
    HTML
  end

  describe '#fetch' do
    before do
      stub_request(:get, /blogtag\.ameba\.jp/)
        .to_return(status: 200, body: html_body, headers: { 'Content-Type' => 'text/html' })
    end

    it '記事リストを返す' do
      results = scraper.fetch
      expect(results).not_to be_empty
    end

    it 'sourceがamebloになっている' do
      results = scraper.fetch
      expect(results).to all(include(source: 'ameblo'))
    end

    it 'title, urlが含まれる' do
      results = scraper.fetch
      expect(results.first).to include(:title, :url)
    end

    it 'URLの重複が排除される' do
      results = scraper.fetch
      urls = results.map { |r| r[:url] }
      expect(urls).to eq(urls.uniq)
    end
  end

  describe '#fetch エラーの場合' do
    before do
      stub_request(:get, /blogtag\.ameba\.jp/).to_return(status: 503)
    end

    it '空配列を返す' do
      results = scraper.fetch
      expect(results).to eq([])
    end
  end
end
