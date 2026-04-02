# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for SaveAction configuration class.
# Verifies on_save cascade to on_create/on_update and integration through
# ExtraOptions initialization (clean_save_action_def behavior).
RSpec.describe 'ExtraOptionConfigs::SaveAction', type: :model do
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

  let(:klass) { OptionConfigs::ExtraOptionConfigs::SaveAction }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:save_action)
    end
  end

  describe 'initialization' do
    it 'cascades on_save to on_create and on_update' do
      instance = klass.new(on_save: { label: 'Saved' })
      expect(instance.save_action[:on_create]).to eq(label: 'Saved')
      expect(instance.save_action[:on_update]).to eq(label: 'Saved')
    end

    it 'merges on_save into existing on_create and on_update' do
      instance = klass.new(on_save: { label: 'Default', notify: true }, on_create: { label: 'Created' })
      expect(instance.save_action[:on_create][:label]).to eq 'Created'
      expect(instance.save_action[:on_create][:notify]).to eq true
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'symbolizes keys for backward compatibility' do
      instance = klass.new(label: 'Test')
      expect(instance.symbolize_keys).to eq(label: 'Test')
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults save_action to a blank SaveAction when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No save action
      YAML
      expect(eo.save_action).to be_a OptionConfigs::ExtraOptionConfigs::SaveAction
      expect(eo.save_action).to be_blank
    end

    it 'cascades on_save to on_create and on_update as defaults' do
      eo = config_for(<<~YAML)
        default:
          save_action:
            on_save:
              label: Saved
      YAML

      expect(eo.save_action.save_action[:on_save]).to eq(label: 'Saved')
      expect(eo.save_action.save_action[:on_create]).to eq(label: 'Saved')
      expect(eo.save_action.save_action[:on_update]).to eq(label: 'Saved')
    end

    it 'merges on_save into existing on_create and on_update without overwriting them' do
      eo = config_for(<<~YAML)
        default:
          save_action:
            on_save:
              label: Default
              notify: true
            on_create:
              label: Created
            on_update:
              another_key: updated_val
      YAML

      expect(eo.save_action.save_action[:on_create][:label]).to eq 'Created'
      expect(eo.save_action.save_action[:on_create][:notify]).to eq true
      expect(eo.save_action.save_action[:on_update][:label]).to eq 'Default'
      expect(eo.save_action.save_action[:on_update][:another_key]).to eq 'updated_val'
    end

    it 'symbolizes save_action keys' do
      eo = config_for(<<~YAML)
        default:
          save_action:
            on_save:
              label: Test
      YAML
      expect(eo.save_action.save_action.keys).to all(be_a Symbol)
    end
  end
end
