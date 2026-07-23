# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for BatchTrigger configuration class.
# Verifies BaseConfiguration inheritance, TriggerTasks typed attributes,
# and integration through ExtraOptions initialization (clean_batch_triggers behavior).
RSpec.describe 'ExtraOptionConfigs::BatchTrigger', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:each) do
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_histories
    @dm = generate_test_dynamic_model
    setup_access :dynamic_model__test_created_by_recs, user: @user
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::BatchTrigger }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares on_record as a typed attribute with TriggerTasks type' do
      expect(klass.option_types[:typed]).to include(:on_record)
      expect(klass.typed_attribute_types[:on_record]).to eq(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
    end
  end

  describe 'initialization' do
    it 'initializes on_record as a TriggerTasks instance from hash' do
      instance = klass.new(on_record: { notify: { type: 'email' } })
      expect(instance.on_record).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_record.tasks).to eq(notify: { type: 'email' })
    end

    it 'initializes on_record as blank TriggerTasks when not provided' do
      instance = klass.new({})
      expect(instance.on_record).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_record).to be_blank
    end

    it 'supports hash-like bracket access for on_record' do
      instance = klass.new(on_record: { action: 'process' })
      expect(instance[:on_record]).to be_a(Hash)
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'reports an error when initialized with a scalar instead of a hash' do
      instance = klass.new('bad')
      expect(instance.config_errors).not_to be_empty
      expect(instance.errors[:batch_trigger]).not_to be_empty
    end

    it 'reports an error when on_record is not a hash or array' do
      instance = klass.new(on_record: 'bad')
      expect(instance.config_errors).not_to be_empty
      expect(instance.errors[:batch_trigger]).not_to be_empty
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults batch_trigger to a BatchTrigger with blank on_record TriggerTasks' do
      eo = config_for(<<~YAML)
        default:
          label: No batch triggers
      YAML

      expect(eo.batch_trigger).to be_a OptionConfigs::ExtraOptionConfigs::BatchTrigger
      expect(eo.batch_trigger[:on_record]).to be_a Hash
      expect(eo.batch_trigger[:on_record]).to be_blank
    end

    it 'preserves batch_trigger configuration and symbolizes keys' do
      eo = config_for(<<~YAML)
        default:
          batch_trigger:
            on_record:
              action: process
      YAML

      expect(eo.batch_trigger[:on_record]).to be_a Hash
      expect(eo.batch_trigger[:on_record]).to eq(action: 'process')
    end
  end
end
