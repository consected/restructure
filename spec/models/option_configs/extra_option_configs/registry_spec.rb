# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Tests for ConfigBase, config_class_registry, config_class_attributes,
# field-keyed and typed class structure, configure_direct, and
# configure_typed_attribute — the infrastructure that underpins
# all ExtraOptionConfigs subclasses.
RSpec.describe 'ExtraOptionConfigs registry and class structure', type: :model do
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

  # ──────────────────────────────────────────────────────────────
  # ConfigBase
  # ──────────────────────────────────────────────────────────────
  describe 'OptionConfigs::ExtraOptionConfigs::ConfigBase' do
    it 'exists as a class' do
      expect(OptionConfigs::ExtraOptionConfigs::ConfigBase).to be_a Class
    end

    it 'includes ActiveModel::Validations' do
      expect(OptionConfigs::ExtraOptionConfigs::ConfigBase.ancestors).to include(ActiveModel::Validations)
    end

    it 'provides managed_attributes class method' do
      expect(OptionConfigs::ExtraOptionConfigs::ConfigBase).to respond_to(:managed_attributes)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Registry key alignment and config_class_attributes
  # ──────────────────────────────────────────────────────────────
  describe 'config_class_registry and config_class_attributes' do
    it 'config_class_registry keys match ExtraOptions attribute names' do
      registry = OptionConfigs::ExtraOptions.config_class_registry
      ExtraOptionConfigsSupport::EXPECTED_CONFIG_CLASSES.each_key do |attr_key|
        expect(registry).to have_key(attr_key),
                            "Expected config_class_registry to have key :#{attr_key}"
      end
    end

    it 'registry class names are singular (no trailing s on Triggers/Variables)' do
      registry = OptionConfigs::ExtraOptions.config_class_registry
      expect(registry[:save_trigger].name).to include('SaveTrigger')
      expect(registry[:save_trigger].name).not_to include('SaveTriggers')
      expect(registry[:batch_trigger].name).to include('BatchTrigger')
      expect(registry[:batch_trigger].name).not_to include('BatchTriggers')
      expect(registry[:config_trigger].name).to include('ConfigTrigger')
      expect(registry[:config_trigger].name).not_to include('ConfigTriggers')
      expect(registry[:set_variables].name).to include('SetVariable')
    end

    it 'AccessIf is split into CreatableIf, EditableIf, ShowableIf' do
      registry = OptionConfigs::ExtraOptions.config_class_registry
      expect(registry).not_to have_key(:access_if)
      expect(registry).to have_key(:creatable_if)
      expect(registry).to have_key(:editable_if)
      expect(registry).to have_key(:showable_if)
    end

    it 'provides config_class_attributes derived from registry keys' do
      attrs = OptionConfigs::ExtraOptions.config_class_attributes
      expect(attrs).to be_an Array
      ExtraOptionConfigsSupport::EXPECTED_CONFIG_CLASSES.each_key do |key|
        expect(attrs).to include(key),
                         "Expected config_class_attributes to include :#{key}"
      end
    end

    it 'base_key_attributes does not overlap config class attributes (except source_attribute keys)' do
      base = OptionConfigs::ExtraOptions.base_key_attributes
      config_attrs = OptionConfigs::ExtraOptions.config_class_attributes
      # source_attribute classes read from a base_key_attribute, so :references
      # appears in base_key_attributes but not in config_class_attributes
      overlap = base & config_attrs
      expect(overlap).to be_empty,
                         "base_key_attributes should not overlap config_class_attributes, but found: #{overlap}"
    end

    it 'base_key_attributes includes source_attribute keys for source_attribute classes' do
      base = OptionConfigs::ExtraOptions.base_key_attributes
      registry = OptionConfigs::ExtraOptions.config_class_registry
      registry.each do |_key, config_class|
        next unless config_class.respond_to?(:source_attribute) && config_class.source_attribute

        expect(base).to include(config_class.source_attribute),
                         "Expected base_key_attributes to include :#{config_class.source_attribute} " \
                         "for source_attribute class #{config_class.name}"
      end
    end

    it 'key_attributes includes both base and config class attributes' do
      all = OptionConfigs::ExtraOptions.key_attributes
      base = OptionConfigs::ExtraOptions.base_key_attributes
      config = OptionConfigs::ExtraOptions.config_class_attributes
      expect(all).to include(*base)
      expect(all).to include(*config)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # configure_typed_attribute in OptionsHandler
  # ──────────────────────────────────────────────────────────────
  describe 'configure_typed_attribute' do
    it 'is available as a class method via OptionsHandler' do
      expect(OptionConfigs::BaseNamedConfiguration).to respond_to(:configure_typed_attribute)
    end

    it 'registers the attribute in option_types[:typed]' do
      test_class = Class.new(OptionConfigs::BaseNamedConfiguration) do
        configure_typed_attribute :test_conditions, type: OptionConfigs::ExtraOptionConfigs::IfCondition
        def config_text = nil
      end
      expect(test_class.option_types[:typed]).to include(:test_conditions)
    end

    it 'stores the type class reference in typed_attribute_types' do
      test_class = Class.new(OptionConfigs::BaseNamedConfiguration) do
        configure_typed_attribute :test_conditions, type: OptionConfigs::ExtraOptionConfigs::IfCondition
        def config_text = nil
      end
      expect(test_class.typed_attribute_types[:test_conditions]).to eq(OptionConfigs::ExtraOptionConfigs::IfCondition)
    end

    it 'auto-initializes the attribute from hash configuration' do
      test_class = Class.new(OptionConfigs::BaseNamedConfiguration) do
        configure_typed_attribute :test_conditions, type: OptionConfigs::ExtraOptionConfigs::IfCondition
        def config_text = nil

        def config_text=(_value); end
      end
      instance = test_class.new(nil, use_hash_config: { test_conditions: { always: true } })
      expect(instance.test_conditions).to be_a(OptionConfigs::ExtraOptionConfigs::IfCondition)
      expect(instance.test_conditions.conditions).to eq(always: true)
    end

    it 'handles nil hash configuration value gracefully' do
      test_class = Class.new(OptionConfigs::BaseNamedConfiguration) do
        configure_typed_attribute :test_conditions, type: OptionConfigs::ExtraOptionConfigs::IfCondition
        def config_text = nil

        def config_text=(_value); end
      end
      instance = test_class.new(nil, use_hash_config: { test_conditions: nil })
      expect(instance.test_conditions).to be_a(OptionConfigs::ExtraOptionConfigs::IfCondition)
      expect(instance.test_conditions).to be_blank
    end
  end

  # ──────────────────────────────────────────────────────────────
  # configure_direct in OptionsHandler
  # ──────────────────────────────────────────────────────────────
  describe 'configure_direct' do
    it 'is available as a class method via OptionsHandler' do
      expect(OptionConfigs::BaseNamedConfiguration).to respond_to(:configure_direct)
    end

    it 'records the direct type in option_types[:direct]' do
      label_klass = OptionConfigs::ExtraOptionConfigs::Label
      expect(label_klass.option_types[:direct]).to be_present
    end

    it 'Fields declares configure_direct type: :array' do
      fields_klass = OptionConfigs::ExtraOptionConfigs::Fields
      expect(fields_klass.option_types[:direct]).to include(:fields)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Field-keyed BaseConfiguration classes
  # ──────────────────────────────────────────────────────────────
  describe 'Field-keyed BaseConfiguration classes' do
    ExtraOptionConfigsSupport::FIELD_KEYED_CLASSES.each do |class_name|
      context "#{class_name}" do
        let(:klass) { "OptionConfigs::ExtraOptionConfigs::#{class_name}".constantize }

        it 'exists under OptionConfigs::ExtraOptionConfigs namespace' do
          expect(klass).to be_a Class
        end

        it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
          expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
        end

        it 'supports hash-like interface ([], keys, key?, blank?, merge!, symbolize_keys)' do
          instance = klass.new({})
          expect(instance).to respond_to(:[], :keys, :key?, :blank?, :merge!, :symbolize_keys)
        end

        it 'is blank when initialized with empty hash' do
          instance = klass.new({})
          expect(instance).to be_blank
        end

        it 'supports JSON serialization' do
          instance = klass.new({})
          expect(JSON.parse(instance.to_json)).to eq({})
        end

        it 'provides error collection arrays' do
          instance = klass.new({})
          expect(instance.config_errors).to eq([])
          expect(instance.config_warnings).to eq([])
        end
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # ConfigBase configuration classes exist with correct structure
  # (CONFIGBASE_CLASSES is empty since all migrated to BaseConfiguration)
  # ──────────────────────────────────────────────────────────────
  describe 'ConfigBase configuration classes exist with correct structure' do
    # CONFIGBASE_CLASSES is empty — all classes converted to BaseConfiguration
    # This section kept as a placeholder to confirm no ConfigBase classes remain
    it 'confirms no ConfigBase subclasses remain in the registry' do
      registry = OptionConfigs::ExtraOptions.config_class_registry
      registry.each_value do |klass|
        expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase),
                                       "#{klass.name} should not inherit from ConfigBase"
      end
    end
  end
end
