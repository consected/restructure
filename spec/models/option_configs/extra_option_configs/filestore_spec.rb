# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for Filestore configuration class.
# Verifies configure_direct with type :hash and integration through
# ExtraOptions initialization (clean_filestore_def behavior).
RSpec.describe 'ExtraOptionConfigs::Filestore', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::Filestore }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:filestore)
    end
  end

  describe 'initialization' do
    it 'stores entire hash as single attribute' do
      instance = klass.new(container: { path: '/test' })
      expect(instance.filestore).to eq(container: { path: '/test' })
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'symbolizes keys for backward compatibility' do
      instance = klass.new(container: {})
      expect(instance.symbolize_keys).to eq(container: {})
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults filestore to a blank Filestore when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No filestore
      YAML
      expect(eo.filestore).to be_a OptionConfigs::ExtraOptionConfigs::Filestore
      expect(eo.filestore).to be_blank
    end

    it 'preserves and symbolizes filestore keys' do
      eo = config_for(<<~YAML)
        default:
          filestore:
            always_use_this_for_access_control: true
      YAML
      expect(eo.filestore.symbolize_keys).to eq(always_use_this_for_access_control: true)
    end
  end
end
