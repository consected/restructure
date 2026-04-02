# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for FieldOptions configuration class.
# Verifies NamedConfiguration for per-field options (edit_as, value, pattern, etc.),
# alt_options preprocessing, and integration through
# ExtraOptions initialization (clean_field_options_def behavior).
RSpec.describe 'ExtraOptionConfigs::FieldOptions', type: :model do
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

  let(:klass) { OptionConfigs::ExtraOptionConfigs::FieldOptions }

  describe 'class structure' do
    it 'defines a NamedConfiguration inner class' do
      expect(klass.const_defined?(:NamedConfiguration)).to be true
    end

    it 'NamedConfiguration declares field option attributes' do
      nc = klass::NamedConfiguration
      expected = %i[
        include_blank pattern value blank_value preset_value blank_preset_value
        active_value no_downcase view_original_case view_with_formats format
        config edit_as calculate_with prompt use_app_type selected show_expanded
        keep_label
      ]
      expected.each { |attr| expect(nc.option_types[:simple]).to include(attr) }
    end
  end

  describe 'initialization' do
    it 'creates NamedConfiguration entries for hash values' do
      instance = klass.new(field1: { no_downcase: true, pattern: '.+' })
      expect(instance[:field1]).to be_a(klass::NamedConfiguration)
      expect(instance[:field1].no_downcase).to be true
      expect(instance[:field1].pattern).to eq '.+'
    end

    it 'stores non-hash values directly' do
      instance = klass.new(field1: 'simple_value')
      expect(instance[:field1]).to eq 'simple_value'
    end

    it 'converts alt_options Array to Hash' do
      instance = klass.new(
        field1: { edit_as: { alt_options: %w[ChoiceA ChoiceB] } }
      )
      ao = instance[:field1][:edit_as][:alt_options]
      expect(ao).to be_a Hash
      expect(ao[:ChoiceA]).to eq 'choicea'
    end

    it 'symbolize_keys converts NamedConfiguration entries to plain hashes' do
      instance = klass.new(field1: { no_downcase: true, value: 'x' })
      result = instance.symbolize_keys
      expect(result[:field1]).to be_a(Hash)
      expect(result[:field1][:no_downcase]).to be true
      expect(result[:field1][:value]).to eq 'x'
    end

    it 'warns about unrecognized keys in field config' do
      instance = klass.new(field1: { no_downcase: true, bogus_key: 'bad' })
      expect(instance[:field1]).to be_a(klass::NamedConfiguration)
      expect(instance.config_warnings).not_to be_empty
    end

    it 'NamedConfiguration supports key? for defined attributes' do
      instance = klass.new(field1: { preset_value: 'abc', no_downcase: true })
      nc = instance[:field1]
      expect(nc).to be_a(klass::NamedConfiguration)
      expect(nc.key?(:preset_value)).to be true
      expect(nc.key?(:no_downcase)).to be true
      expect(nc.key?(:blank_preset_value)).to be false
      expect(nc.key?(:active_value)).to be false
    end

    it 'NamedConfiguration key? returns false for unknown attributes' do
      instance = klass.new(field1: { preset_value: 'abc' })
      nc = instance[:field1]
      expect(nc.key?(:nonexistent_attr)).to be false
    end

    it 'NamedConfiguration supports has_key? alias' do
      instance = klass.new(field1: { preset_value: 'abc' })
      nc = instance[:field1]
      expect(nc.has_key?(:preset_value)).to be true
      expect(nc.has_key?(:active_value)).to be false
    end

    it 'NamedConfiguration supports []= to set attributes for template compatibility' do
      instance = klass.new(field1: { preset_value: 'abc', edit_as: { field_type: 'select' } })
      nc = instance[:field1]
      # Templates set :include_blank and :selected on field option configs
      nc[:include_blank] = true
      expect(nc[:include_blank]).to eq true
      expect(nc.key?(:include_blank)).to be true

      nc[:selected] = 'some_value'
      expect(nc[:selected]).to eq 'some_value'

      nc[:value] = 'override'
      expect(nc[:value]).to eq 'override'
    end

    it 'NamedConfiguration dup returns a plain hash for legacy callers' do
      instance = klass.new(field1: { preset_value: 'abc', edit_as: { field_type: 'select' } })

      expect(instance[:field1].dup).to eq(
        preset_value: 'abc',
        edit_as: { field_type: 'select' }
      )
    end

    it 'NamedConfiguration deep_dup and merge behave like a hash for legacy callers' do
      instance = klass.new(field1: { preset_value: 'abc', edit_as: { field_type: 'select' } })

      merged = instance[:field1].deep_dup.merge(include_blank: true)

      expect(merged).to eq(
        preset_value: 'abc',
        edit_as: { field_type: 'select' },
        include_blank: true
      )
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults field_options to a blank FieldOptions instance when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No field options
      YAML
      expect(eo.field_options).to be_blank
    end

    it 'preserves field_options and symbolizes keys' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          field_options:
            test1:
              no_downcase: true
      YAML
      expect(eo.field_options[:test1]).to eq(no_downcase: true)
    end

    it 'converts edit_as.alt_options from Array to Hash' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          field_options:
            test1:
              edit_as:
                field_type: select
                alt_options:
                  - Choice A
                  - Choice B
      YAML

      ao = eo.field_options[:test1][:edit_as][:alt_options]
      expect(ao).to be_a Hash
      expect(ao[:'Choice A']).to eq 'choice a'
      expect(ao[:'Choice B']).to eq 'choice b'
    end

    it 'preserves edit_as.alt_options when already a Hash' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          field_options:
            test1:
              edit_as:
                field_type: select
                alt_options:
                  'Option 1': opt1
                  'Option 2': opt2
      YAML

      ao = eo.field_options[:test1][:edit_as][:alt_options]
      expect(ao).to be_a Hash
      expect(ao[:'Option 1']).to eq 'opt1'
    end
  end
end
