# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for References configuration class and the source_attribute pattern.
# Verifies:
# - source_attribute reads raw input from :references (a base_key_attribute)
# - references_config stores the References instance with ReferenceEntry named configurations
# - references stores the enriched hash with computed metadata (views consume this)
# - ReferenceEntry holds only admin-configured input keys (round-trip serializable)
# - prepare_config normalization (singularize, composite keys, class resolution)
# - reprocess, validate callbacks, and integration through ExtraOptions initialization
RSpec.describe 'ExtraOptionConfigs::References', type: :model do
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

  let(:klass) { OptionConfigs::ExtraOptionConfigs::References }

  describe 'class structure' do
    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:references)
    end

    it 'defaults to nil when initialized with nil' do
      instance = klass.new(nil)
      expect(instance.references).to be_nil
    end

    it 'declares source_attribute as :references' do
      expect(klass.source_attribute).to eq(:references)
    end

    it 'has store_processed_value? returning true' do
      expect(klass.store_processed_value?).to be(true)
    end

    it 'defines NamedConfiguration with admin input attributes' do
      expect(klass.const_defined?(:NamedConfiguration)).to be(true)
      nc = klass::NamedConfiguration
      expected_attrs = %i[
        label result_label from without_reference add add_with
        filter_by order_by limit type_config
        view_as view_options showable_if creatable_if
        prevent_disable also_disable_record allow_disable_if_not_editable
        prevent_reload_on_save action_position
      ]
      expected_attrs.each do |attr|
        expect(nc.option_types[:simple]).to include(attr),
                                            "Expected NamedConfiguration to have attribute :#{attr}"
      end
    end

    it 'aliases NamedConfiguration as ReferenceEntry' do
      expect(klass::ReferenceEntry).to eq(klass::NamedConfiguration)
    end
  end

  describe 'validate callbacks' do
    it 'produces ActiveModel errors on the instance when reference class does not exist' do
      yaml = <<~YAML
        default:
          label: Test
          references:
            nonexistent_model_xyz_999:
              from: this
              add: many
      YAML
      eo = config_for(yaml)

      raw = { nonexistent_model_xyz_999: { from: 'this', add: 'many' } }
      processed = klass.prepare_config(raw, eo)
      instance = klass.new(processed)
      expect(instance.errors.any? { |e| e.attribute == :references }).to be(true),
                                                                         'Expected ActiveModel error on :references for non-existent class, but none found on instance'
    end

    it 'has no ActiveModel errors on the instance when references are valid' do
      yaml = <<~YAML
        default:
          label: Test
          references:
            player_contact:
              from: this
              add: many
      YAML
      eo = config_for(yaml)

      raw = { player_contact: { from: 'this', add: 'many' } }
      processed = klass.prepare_config(raw, eo)
      instance = klass.new(processed)
      expect(instance.errors).to be_empty,
                                 "Expected no ActiveModel errors for valid references, got: #{instance.errors.full_messages}"
    end

    it 'produces ActiveModel errors when initialized with a top-level validation error' do
      instance = klass.new(_validation_errors: ['references must be a Hash or an Array of Hash entries'])
      expect(instance.errors[:references]).not_to be_empty
    end

    it 'produces ActiveModel errors when a reference entry is not a hash' do
      yaml = <<~YAML
        default:
          label: Test
      YAML
      eo = config_for(yaml)

      processed = klass.prepare_config({ player_contact: 'bad' }, eo)
      instance = klass.new(processed)
      expect(instance.errors[:references]).not_to be_empty
    end
  end

  describe 'reference entry attribute type validation' do
    before(:each) do
      @eo = config_for("default:\n  label: Test\n")
    end

    it 'rejects a non-integer limit with a config error' do
      processed = klass.prepare_config({ player_contact: { from: 'this', add: 'many', limit: 'five' } }, @eo)
      instance = klass.new(processed)
      expect(instance.config_errors.any? { |e| e[:message].include?('limit must be an integer') }).to be(true)
    end

    it 'rejects a non-boolean prevent_disable with a config error' do
      processed = klass.prepare_config({ player_contact: { from: 'this', add: 'many', prevent_disable: 'yes' } }, @eo)
      instance = klass.new(processed)
      expect(instance.config_errors.any? { |e| e[:message].include?('prevent_disable must be true or false') }).to be(true)
    end
  end

  describe 'References.reprocess' do
    it 'exists as a class method on References' do
      expect(klass).to respond_to(:reprocess)
    end

    it 're-processes references after post-initialization mutation' do
      yaml = <<~YAML
        default:
          label: Test
          references:
            player_contact:
              from: this
              add: many
      YAML
      eo = config_for(yaml)

      # Initial references should have been processed
      expect(eo.references).to be_a(Hash)
      initial_ref = eo.references[:player_contact]
      expect(initial_ref).to be_present
      expect(initial_ref[:player_contact][:to_record_label]).to be_present

      # Mutate references with a raw hash using plural keys
      eo.references = { player_contacts: { from: 'this', add: 'many' } }

      # Call reprocess to re-run prepare_config on the mutated value
      klass.reprocess(eo)

      # After reprocessing, plural keys should be singularized
      expect(eo.references).to be_a(Hash)
      reprocessed_ref = eo.references[:player_contact]
      expect(reprocessed_ref).to be_present, 'Expected plural key :player_contacts to be singularized to :player_contact'
      expect(reprocessed_ref[:player_contact][:to_record_label]).to be_present
    end
  end

  describe 'ExtraOptions integration' do
    it 'leaves references as nil when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No references
      YAML
      expect(eo.references).to be_nil
    end

    it 'converts a hash-style references, singularizing keys' do
      eo = config_for(<<~YAML)
        default:
          references:
            player_infos:
              label: Player Info Ref
      YAML

      expect(eo.references).to be_a Hash
      ref_keys = eo.references.keys
      ref_keys.each do |k|
        inner = eo.references[k]
        expect(inner).to be_a Hash
      end
    end

    it 'converts an array-style references to a hash' do
      eo = config_for(<<~YAML)
        default:
          references:
            - player_infos:
                label: Player Info Ref
      YAML

      expect(eo.references).to be_a Hash
    end

    it 'warns when a referenced model does not exist' do
      eo = config_for(<<~YAML)
        default:
          references:
            nonexistent_model_xyz:
              label: Bad Reference
      YAML

      has_warning = eo.config_warnings.any? { |w| w[:type] == :references }
      expect(eo.references).to be_a Hash
    end
  end

  describe 'source_attribute integration' do
    it 'stores the References instance at references_config' do
      eo = config_for(<<~YAML)
        default:
          references:
            player_contact:
              label: Contact
              from: this
              add: many
      YAML

      expect(eo.references_config).to be_a(klass)
    end

    it 'stores the enriched hash at references' do
      eo = config_for(<<~YAML)
        default:
          references:
            player_contact:
              label: Contact
              from: this
              add: many
      YAML

      expect(eo.references).to be_a(Hash)
      inner = eo.references[:player_contact]
      expect(inner).to be_a(Hash)
      expect(inner[:player_contact][:to_record_label]).to be_present
      expect(inner[:player_contact][:to_model_name_us]).to be_present
    end

    it 'references_config.configurations holds ReferenceEntry objects with input-only keys' do
      eo = config_for(<<~YAML)
        default:
          references:
            player_contact:
              label: Contact
              from: this
              add: many
              filter_by:
                rec_type: test
      YAML

      rc = eo.references_config
      expect(rc.configurations).to be_a(Hash)

      entry = rc.configurations[:player_contact]
      expect(entry).to be_a(klass::ReferenceEntry)
      expect(entry[:label]).to eq('Contact')
      expect(entry[:from]).to eq('this')
      expect(entry[:add]).to eq('many')
      expect(entry[:filter_by]).to eq({ rec_type: 'test' })

      # Computed keys should NOT be in the ReferenceEntry
      klass::COMPUTED_KEYS.each do |computed_key|
        expect(entry[computed_key]).to be_nil,
                                       "Expected ReferenceEntry NOT to contain computed key :#{computed_key}"
      end
    end

    it 'references_config is nil when no references are configured' do
      eo = config_for(<<~YAML)
        default:
          label: No references
      YAML

      expect(eo.references_config).to be_a(klass)
      expect(eo.references_config.configurations).to be_empty
    end

    it 'collects errors/warnings via references_config (not lost on source_attribute pattern)' do
      eo = config_for(<<~YAML)
        default:
          references:
            nonexistent_model_xyz:
              label: Bad Reference
      YAML

      has_warning = eo.config_warnings.any? { |w| w[:type].to_s == 'references' }
      expect(has_warning).to be(true), 'Expected config_warnings to include a :references warning'
    end
  end
end
