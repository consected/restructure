# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for Embed configuration class.
# Verifies source_attribute pattern, configure_attributes, COMPUTED_KEYS,
# resource_name handling, validate callbacks, and integration through
# ExtraOptions initialization with enriched hash and instance separation.
RSpec.describe 'ExtraOptionConfigs::Embed', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  let(:klass) { OptionConfigs::ExtraOptionConfigs::Embed }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'declares source_attribute :embed' do
      expect(klass.source_attribute).to eq :embed
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:embed)
    end

    it 'declares configure_attributes for input-only fields' do
      expect(klass.option_types[:simple]).to include(:resource_name, :resource_id, :limit)
    end

    it 'defines COMPUTED_KEYS for enrichment-only keys' do
      expect(klass::COMPUTED_KEYS).to eq %i[resource_model_def]
    end
  end

  describe 'initialization' do
    it 'stores resource_name from string input' do
      instance = klass.new('some_resource')
      expect(instance.embed[:resource_name]).to eq 'some_resource'
    end

    it 'assigns input-only configure_attributes from hash input' do
      instance = klass.new(resource_name: 'some_resource', resource_id: 42, limit: 1)
      expect(instance.resource_name).to eq 'some_resource'
      expect(instance.resource_id).to eq 42
      expect(instance.limit).to eq 1
    end

    it 'does not assign computed keys to configure_attributes' do
      instance = klass.new(resource_name: 'test', resource_model_def: { model: 'fake' })
      expect(instance.embed[:resource_model_def]).to eq({ model: 'fake' })
      expect(instance).not_to respond_to(:resource_model_def)
    end

    it 'returns blank when initialized with nil' do
      instance = klass.new(nil)
      expect(instance).to be_blank
    end

    it 'reports an error when prepared from an unsupported type' do
      yaml = <<~YAML
        default:
          label: Test
      YAML
      eo = config_for(yaml)

      processed = klass.prepare_config(123, eo)
      instance = klass.new(processed)
      expect(instance.config_errors).not_to be_empty
      expect(instance.errors[:embed]).not_to be_empty
    end

    it 'warns on unrecognized hash keys' do
      instance = klass.new(resource_name: 'some_resource', unexpected: true)
      expect(instance.config_warnings).not_to be_empty
      expect(instance.errors[:embed]).not_to be_empty
    end
  end

  describe 'validate callbacks' do
    it 'produces ActiveModel errors on the instance when resource does not exist' do
      yaml = <<~YAML
        default:
          label: Test
          embed: nonexistent_resource_xyz_999
      YAML
      eo = config_for(yaml)

      processed = klass.prepare_config('nonexistent_resource_xyz_999', eo)
      instance = klass.new(processed)
      expect(instance.errors.any? { |e| e.attribute == :embed }).to be(true),
                                                                    'Expected ActiveModel error on :embed for non-existent resource, but none found on instance'
    end

    it 'has no ActiveModel errors on the instance when embed is valid' do
      yaml = <<~YAML
        default:
          label: Test
          embed: player_contacts
      YAML
      eo = config_for(yaml)

      processed = klass.prepare_config('player_contacts', eo)
      instance = klass.new(processed)
      expect(instance.errors).to be_empty,
                                 "Expected no ActiveModel errors for valid embed, got: #{instance.errors.full_messages}"
    end
  end

  describe 'ExtraOptions integration' do
    it 'leaves embed as nil when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No embed
      YAML
      expect(eo.embed).to be_nil
    end

    it 'converts a string resource_name into an enriched hash with resource_name and resource_model_def' do
      eo = config_for(<<~YAML)
        default:
          embed: dynamic_model__some_resource
      YAML

      expect(eo.embed).to be_a Hash
      expect(eo.embed[:resource_name]).to eq 'dynamic_model__some_resource'
      expect(eo.embed).to have_key(:resource_model_def)
    end

    it 'stores the Embed instance at embed_config' do
      eo = config_for(<<~YAML)
        default:
          embed: dynamic_model__some_resource
      YAML

      expect(eo.embed_config).to be_a(klass)
      expect(eo.embed_config.resource_name).to eq 'dynamic_model__some_resource'
    end

    it 'embed_config has input-only attributes without computed keys' do
      eo = config_for(<<~YAML)
        default:
          embed:
            resource_name: dynamic_model__some_resource
            limit: 1
      YAML

      instance = eo.embed_config
      expect(instance.resource_name).to eq 'dynamic_model__some_resource'
      expect(instance.limit).to eq 1
      expect(instance).not_to respond_to(:resource_model_def)
    end

    it 'preserves a hash-style embed with resource_name' do
      eo = config_for(<<~YAML)
        default:
          embed:
            resource_name: dynamic_model__some_resource
      YAML

      expect(eo.embed[:resource_name]).to eq 'dynamic_model__some_resource'
    end

    it 'warns when the embedded resource does not exist' do
      eo = config_for(<<~YAML)
        default:
          embed:
            resource_name: dynamic_model__nonexistent_model
      YAML

      expect(eo.config_warnings).not_to be_empty
      warn = eo.config_warnings.find { |w| w[:type].to_s == 'embed' }
      expect(warn).to be_present
    end
  end
end
