# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bondoro::User do
  let(:db) { instance_double(Bondoro::DynamoDBClient) }

  before do
    allow(Bondoro::DynamoDBClient).to receive(:new).and_return(db)
  end

  describe '.find_or_create' do
    let(:line_user_id) { 'U1234567890abcdef' }

    context '新規ユーザーの場合' do
      before do
        allow(db).to receive(:get_item).and_return(nil)
        allow(db).to receive(:put_item)
      end

      it 'デフォルト設定で登録される' do
        user = described_class.find_or_create(line_user_id: line_user_id)
        expect(user.notification_enabled).to be true
        expect(user.keywords).to eq(described_class::DEFAULT_KEYWORDS)
        expect(user.sources).to eq(described_class::DEFAULT_SOURCES)
      end

      it 'DynamoDBにput_itemが呼ばれる' do
        described_class.find_or_create(line_user_id: line_user_id)
        expect(db).to have_received(:put_item).once
      end
    end

    context '既存ユーザー（通知OFF）の場合' do
      let(:existing_item) do
        {
          'pk' => "USER##{line_user_id}", 'sk' => 'PROFILE',
          'line_user_id' => line_user_id, 'display_name' => 'テストユーザー',
          'notification_enabled' => false,
          'keywords' => described_class::DEFAULT_KEYWORDS,
          'sources' => described_class::DEFAULT_SOURCES,
          'created_at' => '2024-01-01T00:00:00+09:00',
          'updated_at' => '2024-01-01T00:00:00+09:00'
        }
      end

      before do
        allow(db).to receive(:get_item).and_return(existing_item)
        allow(db).to receive(:update_item)
      end

      it '通知が有効化される' do
        user = described_class.find_or_create(line_user_id: line_user_id)
        expect(user.notification_enabled).to be true
      end
    end
  end

  describe '#add_keyword!' do
    let(:user) do
      described_class.new(
        'pk' => 'USER#U123', 'sk' => 'PROFILE',
        'line_user_id' => 'U123', 'notification_enabled' => true,
        'keywords' => ['ボンボンドロップ'], 'sources' => described_class::DEFAULT_SOURCES,
        'created_at' => '2024-01-01T00:00:00+09:00', 'updated_at' => '2024-01-01T00:00:00+09:00'
      )
    end

    before { allow(db).to receive(:update_item) }

    it 'キーワードが追加される' do
      user.add_keyword!('グミシール')
      expect(user.keywords).to include('グミシール')
    end

    it '重複キーワードは追加されない' do
      user.add_keyword!('ボンボンドロップ')
      expect(user.keywords.count('ボンボンドロップ')).to eq(1)
    end
  end

  describe '#remove_keyword!' do
    let(:user) do
      described_class.new(
        'pk' => 'USER#U123', 'sk' => 'PROFILE',
        'line_user_id' => 'U123', 'notification_enabled' => true,
        'keywords' => ['ボンボンドロップ', 'BONBON DROP'],
        'sources' => described_class::DEFAULT_SOURCES,
        'created_at' => '2024-01-01T00:00:00+09:00', 'updated_at' => '2024-01-01T00:00:00+09:00'
      )
    end

    before { allow(db).to receive(:update_item) }

    it 'キーワードが削除される' do
      user.remove_keyword!('BONBON DROP')
      expect(user.keywords).not_to include('BONBON DROP')
    end
  end

  describe '#disable_notification!' do
    let(:user) do
      described_class.new(
        'pk' => 'USER#U123', 'sk' => 'PROFILE',
        'line_user_id' => 'U123', 'notification_enabled' => true,
        'keywords' => described_class::DEFAULT_KEYWORDS,
        'sources' => described_class::DEFAULT_SOURCES,
        'created_at' => '2024-01-01T00:00:00+09:00', 'updated_at' => '2024-01-01T00:00:00+09:00'
      )
    end

    before { allow(db).to receive(:update_item) }

    it '通知がOFFになる' do
      user.disable_notification!
      expect(user.notification_enabled).to be false
    end
  end
end
