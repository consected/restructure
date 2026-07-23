# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for ConfigTrigger configuration class.
# Verifies BaseConfiguration inheritance, TriggerTasks typed attributes,
# and integration through ExtraOptions initialization (clean_config_triggers behavior).
RSpec.describe 'ExtraOptionConfigs::ConfigTrigger', type: :model do
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

  let(:klass) { OptionConfigs::ExtraOptionConfigs::ConfigTrigger }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares on_define as a typed attribute with ConfigTriggerTasks type' do
      expect(klass.option_types[:typed]).to include(:on_define)
      expect(klass.typed_attribute_types[:on_define]).to eq(OptionConfigs::ExtraOptionConfigs::ConfigTriggerTasks)
    end
  end

  describe 'initialization' do
    it 'wraps non-array on_define in an array' do
      instance = klass.new(on_define: { action: 'do_something' })
      expect(instance.on_define).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_define.tasks).to be_an Array
      expect(instance.on_define.tasks.length).to eq 1
    end

    it 'preserves array on_define' do
      instance = klass.new(on_define: [{ action: 'first' }, { action: 'second' }])
      expect(instance.on_define).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_define.tasks).to be_an Array
      expect(instance.on_define.tasks.length).to eq 2
    end

    it 'defaults on_define to blank TriggerTasks when not provided' do
      instance = klass.new({})
      expect(instance.on_define).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_define).to be_blank
    end

    it 'supports hash-like bracket access' do
      instance = klass.new(on_define: [{ action: 'test' }])
      expect(instance[:on_define]).to be_a(Array)
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults config_trigger to a ConfigTrigger with empty on_define TriggerTasks' do
      eo = config_for(<<~YAML)
        default:
          label: No config triggers
      YAML

      expect(eo.config_trigger).to be_a OptionConfigs::ExtraOptionConfigs::ConfigTrigger
      expect(eo.config_trigger[:on_define]).to be_an Array
      expect(eo.config_trigger[:on_define]).to be_blank
    end

    it 'wraps on_define in an array if it is not already an array' do
      eo = config_for(<<~YAML)
        default:
          config_trigger:
            on_define:
              action: do_something
      YAML

      expect(eo.config_trigger[:on_define]).to be_an Array
      expect(eo.config_trigger[:on_define].length).to eq 1
    end

    it 'preserves on_define as an array if already provided' do
      eo = config_for(<<~YAML)
        default:
          config_trigger:
            on_define:
              - action: first
              - action: second
      YAML

      expect(eo.config_trigger[:on_define]).to be_an Array
      expect(eo.config_trigger[:on_define].length).to eq 2
    end
  end
end
