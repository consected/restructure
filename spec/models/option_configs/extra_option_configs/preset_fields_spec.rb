# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for PresetFields configuration class (field-keyed BaseConfiguration).
# Verifies hash-like interface and integration through
# ExtraOptions initialization (clean_preset_fields behavior).
RSpec.describe 'ExtraOptionConfigs::PresetFields', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::PresetFields }

  describe 'initialization' do
    it 'stores preset values directly' do
      instance = klass.new(field1: 'default_val')
      expect(instance[:field1]).to eq 'default_val'
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults preset_fields to a blank PresetFields instance' do
      eo = config_for(<<~YAML)
        default:
          label: No presets
      YAML
      expect(eo.preset_fields).to be_blank
    end

    it 'preserves and symbolizes preset_fields' do
      eo = config_for(<<~YAML)
        default:
          preset_fields:
            test1: default_value
            test2: another_value
      YAML
      expect(eo.preset_fields.symbolize_keys).to eq(test1: 'default_value', test2: 'another_value')
    end
  end
end
