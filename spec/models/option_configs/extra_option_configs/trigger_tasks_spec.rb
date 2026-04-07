# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for TriggerTasks configuration class.
# TriggerTasks is a utility class used by SaveTrigger, BatchTrigger,
# and ConfigTrigger to store trigger task data (either Hash or Array).
RSpec.describe 'ExtraOptionConfigs::TriggerTasks', type: :model do
  let(:klass) { OptionConfigs::ExtraOptionConfigs::TriggerTasks }

  describe 'class structure' do
    it 'exists under ExtraOptionConfigs namespace' do
      expect(klass).to be_a Class
    end

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'declares configure_direct with type :array_or_hash' do
      expect(klass.option_types[:direct]).to include(:tasks)
      expect(klass.direct_types[:tasks]).to eq(:array_or_hash)
    end
  end

  describe 'Hash initialization' do
    it 'stores entire hash as single tasks attribute' do
      instance = klass.new(notify: { type: 'email' }, update_this: { field: 'val' })
      expect(instance.tasks).to eq(notify: { type: 'email' }, update_this: { field: 'val' })
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'handles nil initialization' do
      instance = klass.new(nil)
      expect(instance.tasks).to eq({})
      expect(instance).to be_blank
    end

    it 'symbolizes keys on initialization' do
      instance = klass.new('notify' => { 'type' => 'email' })
      expect(instance.tasks).to have_key(:notify)
    end

    it 'supports symbolize_keys for backward compatibility' do
      instance = klass.new(notify: { type: 'email' })
      expect(instance.symbolize_keys).to eq(notify: { type: 'email' })
    end
  end

  describe 'Array initialization' do
    it 'stores array value as tasks when initialized with an array' do
      arr = [{ notify: { type: 'email' } }, { update_this: { field: 'val' } }]
      instance = klass.new(arr)
      expect(instance.tasks).to eq(arr)
    end

    it 'returns not blank when initialized with a non-empty array' do
      instance = klass.new([{ notify: { type: 'email' } }])
      expect(instance).not_to be_blank
    end

    it 'returns blank when initialized with an empty array' do
      instance = klass.new([])
      expect(instance).to be_blank
    end

    it 'symbolize_keys returns the array as-is when tasks is an array' do
      arr = [{ notify: { type: 'email' } }]
      instance = klass.new(arr)
      expect(instance.symbolize_keys).to eq(arr)
    end

    it 'reports an error when initialized with a scalar instead of a hash or array' do
      instance = klass.new('bad')
      expect(instance.config_errors).not_to be_empty
      expect(instance.errors[:tasks]).not_to be_empty
    end

    it 'reports an error when an array entry is not a hash' do
      instance = klass.new([{ notify: { type: 'email' } }, 'bad'])
      expect(instance.config_errors).not_to be_empty
      expect(instance.errors[:tasks]).not_to be_empty
    end
  end
end
