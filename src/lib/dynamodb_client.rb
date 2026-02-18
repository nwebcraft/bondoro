# frozen_string_literal: true

require 'aws-sdk-dynamodb'

module Bondoro
  class DynamoDBClient
    def initialize
      @client = Aws::DynamoDB::Client.new(region: ENV.fetch('AWS_REGION', 'ap-northeast-1'))
    end

    def get_item(table_name:, pk:, sk:)
      result = @client.get_item(
        table_name: table_name,
        key: { 'pk' => pk, 'sk' => sk }
      )
      result.item
    end

    def put_item(table_name:, item:)
      @client.put_item(
        table_name: table_name,
        item: item
      )
    end

    def update_item(table_name:, pk:, sk:, updates:)
      expression_parts = []
      expression_values = {}
      expression_names = {}

      updates.each_with_index do |(key, value), i|
        placeholder = ":val#{i}"
        name_placeholder = "#attr#{i}"
        expression_parts << "#{name_placeholder} = #{placeholder}"
        expression_values[placeholder] = value
        expression_names[name_placeholder] = key.to_s
      end

      @client.update_item(
        table_name: table_name,
        key: { 'pk' => pk, 'sk' => sk },
        update_expression: "SET #{expression_parts.join(', ')}",
        expression_attribute_values: expression_values,
        expression_attribute_names: expression_names
      )
    end

    def query(table_name:, index_name: nil, key_condition_expression:, expression_attribute_values:, expression_attribute_names: nil, limit: nil)
      params = {
        table_name: table_name,
        key_condition_expression: key_condition_expression,
        expression_attribute_values: expression_attribute_values
      }
      params[:index_name] = index_name if index_name
      params[:expression_attribute_names] = expression_attribute_names if expression_attribute_names
      params[:limit] = limit if limit

      result = @client.query(params)
      result.items
    end

    def scan(table_name:, filter_expression: nil, expression_attribute_values: nil, expression_attribute_names: nil)
      params = { table_name: table_name }
      params[:filter_expression] = filter_expression if filter_expression
      params[:expression_attribute_values] = expression_attribute_values if expression_attribute_values
      params[:expression_attribute_names] = expression_attribute_names if expression_attribute_names

      result = @client.scan(params)
      result.items
    end
  end
end
