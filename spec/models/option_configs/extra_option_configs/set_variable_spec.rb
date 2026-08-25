# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for SetVariable configuration class.
# Verifies configure_direct with type :array, entry validation,
# validate callbacks, and integration through ExtraOptions initialization
# (clean_set_variables_def behavior).
RSpec.describe 'ExtraOptionConfigs::SetVariable', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::SetVariable }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :array' do
      expect(klass.option_types[:direct]).to include(:set_variables)
    end
  end

  describe 'initialization' do
    it 'stores valid array entries' do
      instance = klass.new([{ name: 'var1', value: 'val1' }])
      expect(instance.set_variables).to be_an Array
      expect(instance.set_variables.length).to eq 1
      expect(instance.set_variables[0][:name]).to eq 'var1'
    end

    it 'reports error when value is not an array' do
      instance = klass.new(name: 'var1', value: 'val1')
      expect(instance.config_errors).not_to be_empty
    end

    it 'filters out invalid entries' do
      instance = klass.new([{ name: 'valid', value: 'val' }, { no_name: 'invalid' }])
      expect(instance.set_variables.length).to eq 1
    end

    it 'returns blank when initialized with nil' do
      instance = klass.new(nil)
      expect(instance).to be_blank
    end
  end

  describe 'validate callbacks' do
    it 'with non-array input has errors on :set_variables' do
      instance = klass.new({ name: 'var1', value: 'val1' })
      expect(instance.config_errors).not_to be_empty
      err = instance.config_errors.find { |e| e[:type] == :set_variables }
      expect(err).to be_present
      expect(err[:message]).to match(/must be an array/)
    end

    it 'with invalid entries has errors on :set_variables' do
      instance = klass.new([{ bad_key: 'test' }])
      expect(instance.config_errors).not_to be_empty
      err = instance.config_errors.find { |e| e[:type] == :set_variables }
      expect(err).to be_present
      expect(err[:message]).to match(/must have 'name' and 'value' keys/)
    end

    it 'with valid entries has no validation errors' do
      instance = klass.new([{ name: 'v', value: 'x' }])
      expect(instance.config_errors).to be_empty
    end

    it 'with non-array has ActiveModel errors' do
      instance = klass.new({ name: 'var1', value: 'val1' })
      expect(instance.errors[:set_variables]).not_to be_empty
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults set_variables to nil when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No variables
      YAML
      expect(eo.set_variables).to be_nil
    end

    it 'preserves valid set_variables array entries' do
      eo = config_for(<<~YAML)
        default:
          set_variables:
            - name: var1
              value: val1
            - name: var2
              value: val2
              if:
                always: true
      YAML

      expect(eo.set_variables).to be_an Array
      expect(eo.set_variables.length).to eq 2
      expect(eo.set_variables[0][:name]).to eq 'var1'
      expect(eo.set_variables[0][:value]).to eq 'val1'
      expect(eo.set_variables[1][:name]).to eq 'var2'
      expect(eo.set_variables[1][:if]).to be_present
    end

    it 'reports an error and empties when set_variables is not an array' do
      eo = config_for(<<~YAML)
        default:
          set_variables:
            name: var1
            value: val1
      YAML

      expect(eo.set_variables).to eq []
      expect(eo.config_errors).not_to be_empty
      err = eo.config_errors.find { |e| e[:type].to_s.start_with?('set_variables') }
      expect(err).to be_present
    end

    it 'filters out invalid entries missing name or value keys' do
      eo = config_for(<<~YAML)
        default:
          set_variables:
            - name: valid_var
              value: valid_val
            - no_name_key: invalid
      YAML

      expect(eo.set_variables).to be_an Array
      expect(eo.set_variables.length).to eq 1
      expect(eo.set_variables[0][:name]).to eq 'valid_var'
    end
  end
end
