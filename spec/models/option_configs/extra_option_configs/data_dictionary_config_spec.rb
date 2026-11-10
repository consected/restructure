# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for DataDictionaryConfig class (top-level _data_dictionary options).
# Verifies Hash-like access, recognized key warnings, to_h conversion,
# and integration through ExtraOptions.parse_config.
RSpec.describe 'ExtraOptionConfigs::DataDictionaryConfig', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::DataDictionaryConfig }

  describe 'initialization' do
    it 'stores data dictionary attributes via []' do
      instance = klass.new(study: 'My Study', domain: 'Clinical')
      expect(instance[:study]).to eq 'My Study'
      expect(instance[:domain]).to eq 'Clinical'
    end

    it 'supports dig for nested derived_var_options' do
      instance = klass.new(
        derived_var_options: { name_regex_replace: '_etl$', ref_source_type: 'redcap' }
      )
      expect(instance.dig(:derived_var_options, :name_regex_replace)).to eq '_etl$'
    end

    it 'converts to plain hash via to_h' do
      instance = klass.new(study: 'X', domain: 'Y')
      h = instance.to_h
      expect(h).to be_a(Hash)
      expect(h[:study]).to eq 'X'
    end

    it 'is blank when empty' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'warns about unrecognized keys' do
      instance = klass.new(study: 'X', bogus_key: 'bad')
      expect(instance.config_warnings).not_to be_empty
    end

    it 'does not warn about recognized keys' do
      instance = klass.new(
        study: 'X', domain: 'Y', prevent_update: true,
        fields: { col1: { label: 'override' } },
        derived_var_options: { ref_source_type: 'redcap' }
      )
      expect(instance.config_warnings).to be_empty
    end
  end

  describe 'parse_config integration' do
    it 'wraps _data_dictionary in a DataDictionaryConfig instance' do
      @dm.update!(options: <<~YAML)
        _data_dictionary:
          study: Test Study
          domain: Clinical
        default:
          label: Test
      YAML
      @dm.reload
      @dm.option_configs force: true

      expect(@dm.data_dictionary).to be_a(klass)
      expect(@dm.data_dictionary[:study]).to eq 'Test Study'
      expect(@dm.data_dictionary[:domain]).to eq 'Clinical'
    end

    it 'returns blank DataDictionaryConfig when no _data_dictionary defined' do
      @dm.update!(options: <<~YAML)
        default:
          label: No data dict
      YAML
      @dm.reload
      @dm.option_configs force: true

      expect(@dm.data_dictionary).to be_a(klass)
      expect(@dm.data_dictionary).to be_blank
    end
  end
end
