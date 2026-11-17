# frozen_string_literal: true

# Verifies retry candidates remain stable when each import pass has different config Hash instances.
require 'rails_helper'

RSpec.describe Admin::AppTypeImport::DynamicDefinitionRetries, type: :model do
  it 'retries a failed item by stable key without retrying unrelated items' do
    importer = Admin::AppTypeImport.new({}, nil, format: :raw, skip_fail: false)
    importer.import_results = {}
    importer.import_failures = {}
    importer.dyn_cname = Class.new
    tracker = described_class.new(importer)
    item = { 'table_name' => 'retry_me' }
    unrelated_item = { 'table_name' => 'not_me' }
    attempts = Hash.new(0)

    tracker.run do |retries|
      imported_item = item.deep_dup
      attempts[:matching] += 1 if retries.process?(
        'associated_dynamic_models', imported_item, lookup_existing_with_fields: ['table_name']
      )
      attempts[:unrelated] += 1 if retries.process?(
        'associated_dynamic_models', unrelated_item, lookup_existing_with_fields: ['table_name']
      )

      retries.record('associated_dynamic_models', imported_item,
                     lookup_existing_with_fields: ['table_name'],
                     failed: retries.pass == :first)
    end

    expect(attempts).to eq(matching: 2, unrelated: 1)
  end
end
