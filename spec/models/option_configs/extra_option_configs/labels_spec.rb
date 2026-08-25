# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for Labels configuration class (field-keyed BaseConfiguration).
# Verifies hash-like interface and integration through
# ExtraOptions initialization (clean_labels_def behavior).
RSpec.describe 'ExtraOptionConfigs::Labels', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::Labels }

  describe 'initialization' do
    it 'stores plain string values' do
      instance = klass.new(field1: 'Label One', field2: 'Label Two')
      expect(instance[:field1]).to eq 'Label One'
      expect(instance[:field2]).to eq 'Label Two'
    end

    it 'symbolize_keys returns a plain Hash' do
      instance = klass.new(field1: 'Label One', field2: 'Label Two')
      expect(instance.symbolize_keys).to eq(field1: 'Label One', field2: 'Label Two')
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults labels to a blank Labels instance when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No labels
      YAML
      expect(eo.labels).to be_blank
    end

    it 'preserves explicitly set labels and symbolizes keys' do
      eo = config_for(<<~YAML)
        default:
          labels:
            test1: Test One
            test2: Test Two
      YAML

      expect(eo.labels.symbolize_keys).to eq(test1: 'Test One', test2: 'Test Two')
    end
  end
end
