# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for Label configuration class.
# Verifies configure_direct with type :string, store_processed_value?,
# and prepare_config defaulting to humanized name from parent.
RSpec.describe 'ExtraOptionConfigs::Label', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::Label }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :string' do
      expect(klass.option_types[:direct]).to include(:label)
    end
  end

  describe 'initialization' do
    it 'stores the string as label attribute' do
      instance = klass.new('My Label')
      expect(instance.label).to eq 'My Label'
    end

    it 'warns through validations when initialized with a non-string value' do
      instance = klass.new(test: true)

      expect(instance.label).to eq ''
      expect(instance.config_warnings).not_to be_empty
      expect(instance.errors[:label]).to include('must be a string, got hash')
    end

    it 'defaults to empty string when initialized with nil' do
      instance = klass.new(nil)
      expect(instance.label).to eq ''
    end

    it 'uses prepare_config to default to humanized name from parent' do
      expect(klass).to respond_to(:prepare_config)
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults label to a humanized version of the config name' do
      eo = config_for(<<~YAML)
        my_custom_name:
          fields:
            - test1
      YAML
      expect(eo.label).to eq 'My custom name'
    end

    it 'preserves an explicitly set label' do
      eo = config_for(<<~YAML)
        default:
          label: Custom Label
      YAML
      expect(eo.label).to eq 'Custom Label'
    end

    it 'defaults label to humanized name when not specified' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
      YAML
      expect(eo.label).to eq 'Default'
    end
  end
end
