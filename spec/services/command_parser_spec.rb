# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Bondoro::Services::CommandParser do
  describe '.parse' do
    {
      '設定'             => [:settings, nil],
      '通知ON'           => [:notification_on, nil],
      '通知OFF'          => [:notification_off, nil],
      'キーワード追加 グミシール' => [:add_keyword, 'グミシール'],
      'キーワード削除 グミシール' => [:remove_keyword, 'グミシール'],
      'ヘルプ'           => [:help, nil],
      'こんにちは'        => [:unknown, nil]
    }.each do |input, (expected_command, expected_args)|
      it "「#{input}」を #{expected_command} として解析する" do
        result = described_class.parse(input)
        expect(result.command).to eq(expected_command)
        expect(result.args).to eq(expected_args)
      end
    end
  end
end
