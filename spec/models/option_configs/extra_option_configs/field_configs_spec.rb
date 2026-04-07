# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for FieldConfigs configuration class.
# Verifies field config merging, validation, standalone def integration,
# and validate callbacks through ExtraOptions initialization (clean_field_configs behavior).
RSpec.describe 'ExtraOptionConfigs::FieldConfigs', type: :model do
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

  let(:klass) { OptionConfigs::ExtraOptionConfigs::FieldConfigs }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:field_configs)
    end
  end

  describe 'initialization' do
    it 'stores the hash as field_configs attribute' do
      instance = klass.new(test1: { caption_before: 'Test' })
      expect(instance.field_configs).to eq(test1: { caption_before: 'Test' })
    end

    it 'defaults to empty hash when initialized with nil' do
      instance = klass.new(nil)
      expect(instance.field_configs).to eq({})
    end
  end

  describe 'validate callbacks' do
    it 'produces ActiveModel errors when a field value is not a Hash' do
      yaml = <<~YAML
        default:
          label: Test
          fields:
            - test_field
          field_configs:
            test_field: not_a_hash
      YAML
      eo = config_for(yaml)

      raw = { test_field: 'not_a_hash' }
      processed = klass.prepare_config(raw, eo)
      instance = klass.new(processed)
      expect(instance.errors.any? { |e| e.attribute == :field_configs }).to be(true),
                                                                            'Expected ActiveModel error on :field_configs for non-Hash field value, but none found on instance'
    end

    it 'produces ActiveModel errors when fields are not in the field list' do
      yaml = <<~YAML
        default:
          label: Test
          fields:
            - test_field
          field_configs:
            unknown_field:
              caption_before: Test Caption
      YAML
      eo = config_for(yaml)

      raw = { unknown_field: { caption_before: 'Test Caption' } }
      processed = klass.prepare_config(raw, eo)
      instance = klass.new(processed)
      expect(instance.errors.any? { |e| e.attribute == :field_configs }).to be(true),
                                                                            'Expected ActiveModel error on :field_configs for field not in field list, but none found on instance'
    end

    it 'produces ActiveModel errors when field_configs contain invalid keys' do
      yaml = <<~YAML
        default:
          label: Test
          fields:
            - test_field
          field_configs:
            test_field:
              totally_invalid_key: some_value
      YAML
      eo = config_for(yaml)

      raw = { test_field: { totally_invalid_key: 'some_value' } }
      processed = klass.prepare_config(raw, eo)
      instance = klass.new(processed)
      expect(instance.errors.any? { |e| e.attribute == :field_configs }).to be(true),
                                                                            'Expected ActiveModel error on :field_configs for invalid keys, but none found on instance'
    end

    it 'has no ActiveModel errors when field_configs are valid' do
      yaml = <<~YAML
        default:
          label: Test
          fields:
            - test_field
          field_configs:
            test_field:
              caption_before: A Caption
      YAML
      eo = config_for(yaml)

      raw = { test_field: { caption_before: 'A Caption' } }
      processed = klass.prepare_config(raw, eo)
      instance = klass.new(processed)
      expect(instance.errors).to be_empty,
                                 "Expected no ActiveModel errors for valid field_configs, got: #{instance.errors.full_messages}"
    end
  end

  describe 'ExtraOptions integration' do
    it 'defaults field_configs to an empty hash when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No field configs
      YAML
      expect(eo.field_configs).to eq({})
    end

    it 'merges field_configs into the standalone configs (caption_before, labels, etc.)' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
            - test2
          field_configs:
            test1:
              caption_before: Caption for test1
              labels: Label for test1
            test2:
              show_if:
                test1: some_value
      YAML

      expect(eo.caption_before[:test1]).to be_present
      expect(eo.labels[:test1]).to eq 'Label for test1'
      expect(eo.show_if[:test2]).to eq(test1: 'some_value')
    end

    it 'reports an error when field_configs references fields not in the field list' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          field_configs:
            nonexistent_field:
              labels: Some label
      YAML

      expect(eo.config_errors).not_to be_empty
      err = eo.config_errors.find { |e| e[:type].to_s.start_with?('field_configs') }
      expect(err).to be_present
    end

    it 'reports an error when field_configs contains invalid config keys' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          field_configs:
            test1:
              invalid_key: some value
      YAML

      expect(eo.config_errors).not_to be_empty
      err = eo.config_errors.find { |e| e[:type].to_s.start_with?('field_configs') }
      expect(err).to be_present
    end

    it 'reports an error when a field config value is not a Hash' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          field_configs:
            test1: not_a_hash
      YAML

      expect(eo.config_errors).not_to be_empty
      err = eo.config_errors.find { |e| e[:type].to_s.start_with?('field_configs') }
      expect(err).to be_present
    end

    it 'stores raw_field_configs as a deep clone before standalone defs are merged' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          field_configs:
            test1:
              labels: Raw label
          labels:
            test1: Standalone label
      YAML

      expect(eo.raw_field_configs).to be_a Hash
      expect(eo.raw_field_configs[:test1]).to be_a Hash
      original_fc = eo.field_configs[:test1].dup
      eo.raw_field_configs[:test1][:labels] = 'Modified'
      expect(eo.field_configs[:test1]).to eq original_fc
    end

    it 'merges standalone configs back into field_configs for valid fields' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
            - test2
          labels:
            test1: Standalone Label 1
          caption_before:
            test2: Standalone caption
      YAML

      expect(eo.field_configs[:test1]).to include(labels: 'Standalone Label 1')
      expect(eo.field_configs[:test2]).to be_a Hash
      expect(eo.field_configs[:test2]).to have_key(:caption_before)
    end

    it 'does not include standalone configs for fields not in the field list' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          labels:
            test1: Included
            not_a_field: Excluded
      YAML

      expect(eo.field_configs).not_to have_key(:not_a_field)
    end
  end
end
