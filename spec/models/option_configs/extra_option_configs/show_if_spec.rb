# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for ShowIf configuration class (field-keyed BaseConfiguration).
# Verifies condition hash storage and integration through
# ExtraOptions initialization (clean_show_if_def behavior).
RSpec.describe 'ExtraOptionConfigs::ShowIf', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::ShowIf }

  describe 'initialization' do
    it 'stores arbitrary condition hashes directly' do
      instance = klass.new(field1: { other_field: 'value' })
      expect(instance[:field1]).to eq(other_field: 'value')
    end

    it 'symbolize_keys returns plain Hash of condition hashes' do
      instance = klass.new(field1: { other_field: 'value' })
      expect(instance.symbolize_keys).to eq(field1: { other_field: 'value' })
    end

    it 'reports an error when a field condition is not a hash' do
      instance = klass.new(field1: 'value')
      expect(instance.config_errors).not_to be_empty
      expect(instance.errors[:show_if]).not_to be_empty
    end

    it 'reports an error when initialized with a scalar instead of a hash' do
      instance = klass.new('bad')
      expect(instance.config_errors).not_to be_empty
      expect(instance.errors[:show_if]).not_to be_empty
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults show_if to a blank ShowIf instance when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No show_if
      YAML
      expect(eo.show_if).to be_blank
    end

    it 'preserves explicitly set show_if conditions and symbolizes keys' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
            - test2
          show_if:
            test2:
              test1: some_value
      YAML

      expect(eo.show_if).to have_key(:test2)
      expect(eo.show_if[:test2]).to eq(test1: 'some_value')
    end

    it 'does not overwrite existing show_if when show_if_condition_strings provides a duplicate' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
            - test2
          show_if:
            test2:
              test1: existing_value
          show_if_condition_strings:
            test2: "[test1] = 'other_value'"
      YAML

      expect(eo.show_if[:test2]).to eq(test1: 'existing_value')
    end
  end
end
