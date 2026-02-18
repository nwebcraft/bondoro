# frozen_string_literal: true

require 'spec_helper'
require 'line/bot'

RSpec.describe Bondoro::Handlers::Webhook do
  let(:channel_secret) { 'test_secret' }
  let(:access_token)   { 'test_token' }
  let(:line_user_id)   { 'U1234567890abcdef' }
  let(:line_client_raw) { instance_double(Line::Bot::Client) }
  let(:db) { instance_double(Bondoro::DynamoDBClient) }

  before do
    stub_const('ENV', ENV.to_h.merge(
      'LINE_CHANNEL_SECRET'       => channel_secret,
      'LINE_CHANNEL_ACCESS_TOKEN' => access_token
    ))
    allow(Line::Bot::Client).to receive(:new).and_return(line_client_raw)
    allow(line_client_raw).to receive(:validate_signature).and_return(true)
    allow(line_client_raw).to receive(:get_profile).and_return(
      instance_double(Net::HTTPSuccess, is_a?: true, body: { 'displayName' => 'テストユーザー' }.to_json)
    )
    allow(Bondoro::DynamoDBClient).to receive(:new).and_return(db)
    allow(db).to receive(:get_item).and_return(nil)
    allow(db).to receive(:put_item)
    allow(db).to receive(:update_item)
  end

  def build_event(body)
    {
      'body' => body.to_json,
      'headers' => { 'x-line-signature' => 'dummy' }
    }
  end

  describe '署名検証' do
    before { allow(line_client_raw).to receive(:validate_signature).and_return(false) }

    it '不正な署名は401を返す' do
      event = build_event({ 'events' => [] })
      result = described_class.handler(event: event, context: {})
      expect(result[:statusCode]).to eq(401)
    end
  end

  describe '友だち追加イベント' do
    let(:body) do
      {
        'events' => [{
          'type'   => 'follow',
          'source' => { 'userId' => line_user_id }
        }]
      }
    end

    it 'ユーザーがDynamoDBに登録される' do
      described_class.handler(event: build_event(body), context: {})
      expect(db).to have_received(:put_item)
    end
  end

  describe 'ブロック（unfollow）イベント' do
    let(:existing_user) do
      {
        'pk' => "USER##{line_user_id}", 'sk' => 'PROFILE',
        'line_user_id' => line_user_id, 'notification_enabled' => true,
        'keywords' => Bondoro::User::DEFAULT_KEYWORDS,
        'sources'  => Bondoro::User::DEFAULT_SOURCES,
        'created_at' => '2024-01-01T00:00:00+09:00',
        'updated_at' => '2024-01-01T00:00:00+09:00'
      }
    end

    before { allow(db).to receive(:get_item).and_return(existing_user) }

    it '通知が無効化される' do
      body = {
        'events' => [{
          'type'   => 'unfollow',
          'source' => { 'userId' => line_user_id }
        }]
      }
      described_class.handler(event: build_event(body), context: {})
      expect(db).to have_received(:update_item)
    end
  end
end
