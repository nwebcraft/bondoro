# frozen_string_literal: true

require_relative '../models/product'
require_relative '../models/user'
require_relative 'line_client'
require_relative 'message_formatter'

module Bondoro
  module Services
    class Notifier
      def self.run
        new.run
      end

      def run
        products = Product.unnotified
        if products.empty?
          puts 'No new products to notify'
          return
        end

        puts "Found #{products.size} unnotified product(s)"

        users = User.notifiable
        if users.empty?
          puts 'No users to notify'
          return
        end

        puts "Notifying #{users.size} user(s)"
        messages = MessageFormatter.build(products)
        client = LineClient.new

        user_ids = users.map(&:line_user_id)
        client.multicast(to: user_ids, messages: messages)

        # 通知済みにマーク
        products.each(&:mark_as_notified!)
        puts "Marked #{products.size} product(s) as notified"
      end
    end
  end
end
