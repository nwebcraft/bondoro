# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bondoro::Scrapers::Ameblo do
  subject(:scraper) { described_class.new }

  describe '#fetch' do
    let(:rss_body) do
      <<~RSS
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>アメブロ検索結果</title>
            <item>
              <title>ボンボンドロップシール入荷しました！</title>
              <link>https://ameblo.jp/shop-example/entry-001.html</link>
              <description>本日入荷しました！</description>
            </item>
            <item>
              <title>BONBON DROP 新作が届いた</title>
              <link>https://ameblo.jp/shop-example/entry-002.html</link>
              <description>新作シールです</description>
            </item>
          </channel>
        </rss>
      RSS
    end

    before do
      stub_request(:get, /blog\.ameba\.jp/)
        .to_return(status: 200, body: rss_body, headers: { 'Content-Type' => 'application/rss+xml' })
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

  describe '#fetch RSSエラーの場合' do
    before do
      stub_request(:get, /blog\.ameba\.jp/).to_return(status: 503)
    end

    it '空配列を返す' do
      results = scraper.fetch
      expect(results).to eq([])
    end
  end
end
