# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for Embed configuration class.
# Verifies resource_name handling, validate callbacks, and integration through
# ExtraOptions initialization (clean_embed_def behavior).
RSpec.describe 'ExtraOptionConfigs::Embed', type: :model do
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

  let(:klass) { OptionConfigs::ExtraOptionConfigs::Embed }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:embed)
    end
  end

  describe 'initialization' do
    it 'stores resource_name from string input' do
      instance = klass.new('some_resource')
      expect(instance.embed[:resource_name]).to eq 'some_resource'
    end

    it 'stores resource_name from hash input' do
      instance = klass.new(resource_name: 'some_resource')
      expect(instance.embed[:resource_name]).to eq 'some_resource'
    end

    it 'returns blank when initialized with nil' do
      instance = klass.new(nil)
      expect(instance).to be_blank
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

    it 'converts a string resource_name into a hash with resource_name key' do
      eo = config_for(<<~YAML)
        default:
          embed: dynamic_model__some_resource
      YAML

      expect(eo.embed).to be_a Hash
      expect(eo.embed[:resource_name]).to eq 'dynamic_model__some_resource'
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
      warn = eo.config_warnings.find { |w| w[:type] == :embed }
      expect(warn).to be_present
    end
  end
end
