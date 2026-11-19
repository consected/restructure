# frozen_string_literal: true

# Purpose: verify definition-derived shared cache reads, refreshes, and writes are
# guarded by the worker's definition freshness so stale workers cannot publish partial values.
require 'rails_helper'

RSpec.describe Dynamic::DefinitionCache, type: :model do
  before do
    described_class.delete_all
  end

  it 'serves a cache hit without refreshing dynamic definitions' do
    described_class.write('cache-hit', value: :cached)
    expect(Application).not_to receive(:refresh_dynamic_defs)
    computed_value = :computed

    expect(described_class.fetch('cache-hit') { computed_value }).to eq(:cached)
  end

  it 'writes a computed value when the worker is current' do
    expect(Application).to receive(:refresh_dynamic_defs).once
    allow(described_class).to receive(:definitions_current?).and_return(true)
    complete_value = :complete

    expect(described_class.fetch('current-value') { complete_value }).to eq(:complete)
    expect(described_class.read('current-value')).to eq(:complete)
  end

  it 'returns but does not cache a value computed by a lagging worker' do
    allow(Application).to receive(:refresh_dynamic_defs)
    allow(described_class).to receive(:definitions_current?).and_return(false, true)

    stale_value = described_class.fetch('shared-item-types') { %i[existing incomplete] }
    expect(stale_value).to eq(%i[existing incomplete])
    expect(described_class.read('shared-item-types')).to be_nil

    current_value = described_class.fetch('shared-item-types') { %i[existing complete] }
    expect(current_value).to eq(%i[existing complete])
    expect(described_class.read('shared-item-types')).to eq(%i[existing complete])
  end

  it 'prevents a lagging dynamic-model worker from publishing an incomplete item-type list' do
    Dynamic::DefinitionCache.delete('DynamicModel.item_types')
    allow(Application).to receive(:refresh_dynamic_defs)
    allow(DynamicModel).to receive(:definition_refresh_status).and_return(:definitions_changed, :current)
    allow(ActivityLog).to receive(:definition_refresh_status).and_return(:current)
    allow(ExternalIdentifier).to receive(:definition_refresh_status).and_return(:current)
    incomplete_class = double(attribute_names: ['select_incomplete'], model_name: double(to_s: 'CacheTest'))
    complete_class = double(attribute_names: ['select_complete'], model_name: double(to_s: 'CacheTest'))
    allow(DynamicModel).to receive(:implementation_classes).and_return([incomplete_class], [complete_class])

    expect(DynamicModel.item_types.map(&:to_s)).to include(a_string_matching(/select_incomplete\z/))
    expect(Dynamic::DefinitionCache.read('DynamicModel.item_types')).to be_nil

    expect(DynamicModel.item_types.map(&:to_s)).to include(a_string_matching(/select_complete\z/))
    expect(Dynamic::DefinitionCache.read('DynamicModel.item_types').map(&:to_s))
      .to include(a_string_matching(/select_complete\z/))
  end

  it 'deletes the current token key before an explicit refresh' do
    allow(Application).to receive(:refresh_dynamic_defs)
    allow(described_class).to receive(:definitions_current?).and_return(true)
    described_class.write('refresh-me', value: :old)

    expect(described_class.fetch('refresh-me', refresh: true) { :new }).to eq(:new)
    expect(described_class.read('refresh-me')).to eq(:new)
  end

  it 'deletes all keys written through the definition cache' do
    described_class.write('first', value: :first)
    described_class.write('second', value: :second)

    described_class.delete_all

    expect(described_class.read('first')).to be_nil
    expect(described_class.read('second')).to be_nil
  end
end
