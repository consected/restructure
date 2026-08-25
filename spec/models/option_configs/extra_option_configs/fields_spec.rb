# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for Fields configuration class.
# Verifies configure_direct with type :array and integration through
# ExtraOptions initialization (clean_fields_def behavior).
RSpec.describe 'ExtraOptionConfigs::Fields', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::Fields }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :array' do
      expect(klass.option_types[:direct]).to include(:fields)
    end
  end

  describe 'initialization' do
    it 'stores the array as fields attribute' do
      instance = klass.new(%w[field1 field2])
      expect(instance.fields).to eq %w[field1 field2]
    end

    it 'defaults to empty array when initialized with nil' do
      instance = klass.new(nil)
      expect(instance.fields).to eq []
    end

    it 'adds validation errors when initialized with a non-array value' do
      instance = klass.new('field1')

      expect(instance.fields).to eq []
      expect(instance.config_errors).not_to be_empty
      expect(instance.errors[:fields]).to include('must be an array, got string')
    end

    it 'returns blank when initialized with empty array' do
      instance = klass.new([])
      expect(instance).to be_blank
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults fields to an empty array when not specified in options' do
      eo = config_for(<<~YAML)
        default:
          label: No fields
      YAML
      expect(eo.fields).to be_an Array
    end

    it 'preserves a provided field list' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
            - test2
      YAML
      expect(eo.fields).to eq %w[test1 test2]
    end
  end
end
