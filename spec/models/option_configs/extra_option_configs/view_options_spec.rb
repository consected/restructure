# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for ViewOptions configuration class.
# Verifies configure_direct with type :hash and integration through
# ExtraOptions initialization (clean_view_options_def behavior).
RSpec.describe 'ExtraOptionConfigs::ViewOptions', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::ViewOptions }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:view_options)
    end
  end

  describe 'initialization' do
    it 'stores entire hash as single attribute' do
      instance = klass.new(data_attribute: 'field_1', show_embedded: true)
      expect(instance.view_options).to eq(data_attribute: 'field_1', show_embedded: true)
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'symbolizes keys for backward compatibility' do
      instance = klass.new(data_attribute: 'test')
      expect(instance.symbolize_keys).to eq(data_attribute: 'test')
    end

    it 'warns on unrecognized keys' do
      instance = klass.new(not_a_real_key: true)
      expect(instance.config_warnings).not_to be_empty
    end

    it 'reports an error when sort_references.keep_top is not boolean' do
      instance = klass.new(sort_references: { attribute: 'id', keep_top: 'yes' })
      expect(instance.config_errors).not_to be_empty
      expect(instance.errors[:view_options]).not_to be_empty
    end

    it 'includes current value when hide_unless_creatable is not boolean' do
      instance = klass.new(hide_unless_creatable: 'yes')
      error_messages = instance.config_errors.map { |e| e[:message] }

      expect(error_messages.any? do |msg|
        msg.include?('hide_unless_creatable must be true or false') &&
          msg.include?('current value: "yes" (String)')
      end).to be(true)
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults view_options to a blank ViewOptions when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No view options
      YAML
      expect(eo.view_options).to be_a OptionConfigs::ExtraOptionConfigs::ViewOptions
      expect(eo.view_options).to be_blank
    end

    it 'preserves view_options and symbolizes keys' do
      eo = config_for(<<~YAML)
        default:
          view_options:
            data_attribute: field_1
            show_embedded: true
      YAML
      expect(eo.view_options).to be_a OptionConfigs::ExtraOptionConfigs::ViewOptions
      expect(eo.view_options.view_options).to eq(data_attribute: 'field_1', show_embedded: true)
    end
  end
end
