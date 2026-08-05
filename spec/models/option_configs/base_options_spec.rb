# frozen_string_literal: true

require 'rails_helper'

# Purpose: verify BaseOptions can export a reflection-based schema of accepted
# option config structures for both ExtraOptions config classes and trigger types.
RSpec.describe OptionConfigs::BaseOptions, type: :model do
  describe '.accepted_config_schema' do
    subject(:schema) { described_class.accepted_config_schema }

    it 'returns top-level sections for key descriptions, base option configs, and trigger types' do
      expect(schema).to include(:key_type_descriptions, :base_option_configs, :trigger_types)
      expect(schema[:base_option_configs]).to be_a(Hash)
      expect(schema[:trigger_types]).to be_a(Hash)
    end

    it 'includes key type metadata for a base option config key_type rule' do
      view_options = schema.dig(:base_option_configs, :view_options)

      expect(view_options).to include(:class_name, :kind, :key_type_rules)
      expect(view_options[:kind]).to eq(:base_configuration)
      expect(view_options.dig(:key_type_rules, :sort_references, :type)).to eq(:hash)
      expect(view_options.dig(:key_type_rules, :sort_references, :allowed_keys)).to eq(
        %i[attribute direction keep_top null_value]
      )
    end

    it 'includes value pattern metadata for a base option config value_pattern rule' do
      db_configs = schema.dig(:base_option_configs, :db_configs)

      expect(db_configs.dig(:value_patterns, :db_config_hash, :match)).to eq('Hash')
      expect(db_configs.dig(:value_patterns, :db_config_hash, :allowed_keys)).to include(:encrypted)
      expect(db_configs.dig(:value_patterns, :db_config_hash, :key_types, :encrypted, :type)).to eq(:boolean)
    end

    it 'includes nested key type metadata for caption_before value patterns' do
      caption_before = schema.dig(:base_option_configs, :caption_before)

      expect(caption_before.dig(:value_patterns, :caption_hash, :key_types, :caption, :type)).to eq(:string)
      expect(caption_before.dig(:value_patterns, :caption_hash, :key_types, :keep_label, :type)).to eq(:boolean)
    end

    it 'includes pattern and key type metadata for trigger types' do
      create_reference = schema.dig(:trigger_types, :create_reference)

      expect(create_reference[:pattern]).to eq(:named_entry)
      expect(create_reference[:allowed_keys]).to include(:in, :on_complete, :on_failure)
      expect(create_reference.dig(:key_type_rules, :in, :type)).to eq(:string_or_hash)
      expect(create_reference.dig(:key_type_rules, :on_complete, :type)).to eq(:hash_or_array)
    end

    it 'represents delegate trigger types with empty key lists and key rules' do
      background = schema.dig(:trigger_types, :background)

      expect(background[:pattern]).to eq(:delegate)
      expect(background[:allowed_keys]).to eq([])
      expect(background[:key_type_rules]).to eq({})
    end

    it 'serializes schema to YAML when requested' do
      yaml = described_class.accepted_config_schema(format: :yaml)

      expect(yaml).to be_a(String)
      expect(yaml).to include('key_type_descriptions:')
      expect(yaml).to include('trigger_types:')
    end

    it 'serializes schema to JSON when requested' do
      json = described_class.accepted_config_schema(format: :json)

      parsed = JSON.parse(json)
      expect(parsed).to include('key_type_descriptions', 'base_option_configs', 'trigger_types')
      expect(parsed['trigger_types']).to have_key('create_reference')
    end

    it 'raises on unsupported serialization formats' do
      expect do
        described_class.accepted_config_schema(format: :xml)
      end.to raise_error(ArgumentError, /Unsupported schema serialization format/)
    end
  end
end
