# frozen_string_literal: true

# Purpose: verify dynamic-definition refresh checks are repeatable and only become
# verified after a complete successful refresh, so skipped or failed work is retried.
require 'rails_helper'

RSpec.describe Dynamic::DefGenerator, type: :model do
  let(:definition_class) { DynamicModel }
  let(:stored_definition) do
    instance_double(DynamicModel, id: 12, updated_at: Time.zone.parse('2026-01-01 12:00:00'),
                                  resource_name: 'dynamic_model__cache_tests')
  end
  let(:loaded_definition) do
    instance_double(DynamicModel, id: 12, updated_at: Time.zone.parse('2026-01-01 12:00:00'),
                                  resource_name: 'dynamic_model__cache_tests')
  end
  let(:definitions) { [stored_definition] }
  let(:relation) do
    relation = double
    allow(relation).to receive(:to_a).and_return(definitions)
    allow(relation).to receive(:reorder).and_return(relation)
    allow(relation).to receive(:order).and_return(relation)
    allow(relation).to receive(:each) { |&block| definitions.each(&block) }
    relation
  end

  before do
    @original_definition_cache = definition_class.definition_cache.dup
    @original_verified_token = definition_class.instance_variable_get(:@verified_definition_cache_token)
    @original_verified_timestamps = definition_class.instance_variable_get(:@verified_definition_timestamps)
    definition_class.definition_cache.clear
    definition_class.instance_variable_set(:@verified_definition_cache_token, nil)
    definition_class.instance_variable_set(:@verified_definition_timestamps, nil)
    allow(definition_class).to receive(:active_model_configurations).and_return(relation)
    allow(stored_definition).to receive(:table_or_view_ready?).and_return(true)
    allow(stored_definition).to receive(:implementation_class_defined?).and_return(true)
    definition_class.definition_cache[stored_definition.id] = loaded_definition
    allow(Resources::Models).to receive(:find_by).and_return(nil)
    allow(Resources::Models).to receive(:find_by).with(resource_name: stored_definition.resource_name)
        .and_return(double(model: double(definition: loaded_definition)))
  end

  after do
    definition_class.definition_cache.replace(@original_definition_cache)
    definition_class.instance_variable_set(:@verified_definition_cache_token, @original_verified_token)
    definition_class.instance_variable_set(:@verified_definition_timestamps, @original_verified_timestamps)
  end

  it 'performs a real first check and repeats the same status without consuming a change' do
    expect(definition_class).to receive(:active_model_configurations).twice.and_return(relation)

    expect(definition_class.definition_refresh_status).to eq(:unverified)
    expect(definition_class.definition_refresh_status).to eq(:unverified)
  end

  it 'uses the verified shared token as a query-free current fast path' do
    definition_class.mark_definition_refresh_current!
    allow(definition_class).to receive(:active_model_configurations).and_raise('unexpected database query')

    expect(definition_class.definition_refresh_status).to eq(:current)
  end

  it 'detects rapid timestamp changes exactly rather than applying a time tolerance' do
    definition_class.mark_definition_refresh_current!
    allow(stored_definition).to receive(:updated_at).and_return(Time.zone.parse('2026-01-01 12:00:00.500000'))
    allow(loaded_definition).to receive(:updated_at).and_return(Time.zone.parse('2026-01-01 12:00:00'))
    Dynamic::DefinitionCacheVersion.rotate!

    expect(definition_class.definition_refresh_status).to eq(:definitions_changed)
    expect(definition_class.definition_refresh_status).to eq(:definitions_changed)
  end

  it 'retries a skipped definition on the next refresh call' do
    allow(stored_definition).to receive(:table_or_view_ready?).and_return(false)
    expect(definition_class).to receive(:regenerate_from_stored).never

    2.times { definition_class.refresh_outdated }

    expect(stored_definition).to have_received(:table_or_view_ready?).exactly(4).times
    expect(definition_class.instance_variable_get(:@verified_definition_cache_token)).to be_nil
  end

  it 'does not mark a refresh current when regeneration raises, and retries on the next call' do
    allow(stored_definition).to receive(:updated_at).and_return(Time.zone.parse('2026-01-01 12:00:01'))
    allow(loaded_definition).to receive(:updated_at).and_return(Time.zone.parse('2026-01-01 12:00:00'))
    Dynamic::DefinitionCacheVersion.rotate!
    allow(definition_class).to receive(:regenerate_from_stored).and_invoke(->(*) { raise 'refresh failure' }, ->(*) {})

    expect { definition_class.refresh_outdated }.to raise_error('refresh failure')
    expect(definition_class.instance_variable_get(:@verified_definition_cache_token)).to be_nil
    expect { definition_class.refresh_outdated }.not_to raise_error
    expect(definition_class).to have_received(:regenerate_from_stored).twice
  end
end
