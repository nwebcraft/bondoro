# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bondoro::Handlers::Scraper do
  let(:sqs) { instance_double(Aws::SQS::Client) }

  before do
    stub_const('ENV', ENV.to_h.merge(
      'RAKUTEN_APP_ID' => 'test',
      'YAHOO_APP_ID'   => 'test',
      'NOTIFICATION_QUEUE_URL' => 'https://sqs.ap-northeast-1.amazonaws.com/123/test-queue'
    ))

    allow(Aws::SQS::Client).to receive(:new).and_return(sqs)
    allow(sqs).to receive(:send_message)

    # 各スクレイパーをモック
    allow_any_instance_of(Bondoro::Scrapers::Rakuten).to receive(:fetch).and_return([])
    allow_any_instance_of(Bondoro::Scrapers::Yahoo).to receive(:fetch).and_return([])
    allow_any_instance_of(Bondoro::Scrapers::Ameblo).to receive(:fetch).and_return([])
  end

  describe '.handler' do
    it '正常終了で200を返す' do
      result = described_class.handler(event: {}, context: {})
      expect(result[:statusCode]).to eq(200)
    end
  end

  describe '新着商品がある場合' do
    let(:new_item) do
      { title: 'ボンボンドロップシール', url: 'https://example.com', price: 980, source: 'rakuten' }
    end

    before do
      allow_any_instance_of(Bondoro::Scrapers::Rakuten).to receive(:fetch).and_return([new_item])
      allow(Bondoro::Services::Deduplicator).to receive(:process).and_return(
        [instance_double(Bondoro::Product)]
      )
    end

    it 'SQSにメッセージが送信される' do
      described_class.handler(event: {}, context: {})
      expect(sqs).to have_received(:send_message)
    end
  end

  describe '新着商品がない場合' do
    before do
      allow(Bondoro::Services::Deduplicator).to receive(:process).and_return([])
    end

    it 'SQSにメッセージが送信されない' do
      described_class.handler(event: {}, context: {})
      expect(sqs).not_to have_received(:send_message)
    end
  end
end
