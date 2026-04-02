# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Phase 2 of issue #986: Verify configuration classes for ExtraOptions clean methods.
# Each top-level configuration area from ExtraOptions has a dedicated configuration class
# under OptionConfigs::ExtraOptionConfigs:: namespace. These tests verify:
# - All configuration classes exist with correct inheritance
# - Each class declares its managed attributes
# - ExtraOptions stores config instances after initialization
# - Config instance attribute values match ExtraOptions attribute values
# - ActiveModel::Validations is available on all config classes for reflection
# - CaptionBefore uses BaseConfiguration/NamedConfiguration pattern with hash compatibility
RSpec.describe 'ExtraOptionConfigs configuration classes', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport

  before(:each) do
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_histories
    @dm = generate_test_dynamic_model
    setup_access :dynamic_model__test_created_by_recs, user: @user
  end

  # Helper: update the DynamicModel with given YAML options and return the first option config
  def config_for(yaml)
    @dm.update!(options: yaml, current_admin: @admin)
    @dm.option_configs.first
  end

  # All expected config classes with their managed attributes.
  # Registry key must match the ExtraOptions attribute name.
  # Class names are singular (SaveTrigger not SaveTriggers).
  # AccessIf is split into CreatableIf, EditableIf, ShowableIf.
  EXPECTED_CONFIG_CLASSES = {
    fields: :Fields,
    label: :Label,
    caption_before: :CaptionBefore,
    dialog_before: :DialogBefore,
    labels: :Labels,
    show_if: :ShowIf,
    save_action: :SaveAction,
    view_options: :ViewOptions,
    db_configs: :DbConfigs,
    creatable_if: :CreatableIf,
    editable_if: :EditableIf,
    showable_if: :ShowableIf,
    valid_if: :ValidIf,
    filestore: :Filestore,
    field_options: :FieldOptions,
    embed: :Embed,
    references: :References,
    save_trigger: :SaveTrigger,
    batch_trigger: :BatchTrigger,
    config_trigger: :ConfigTrigger,
    preset_fields: :PresetFields,
    set_variables: :SetVariable,
    field_configs: :FieldConfigs
  }.freeze

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
      EXPECTED_CONFIG_CLASSES.each_key do |attr_key|
        expect(registry).to have_key(attr_key),
                            "Expected config_class_registry to have key :#{attr_key}"
      end
    end

    it 'registry class names are singular (no trailing s on Triggers/Variables)' do
      registry = OptionConfigs::ExtraOptions.config_class_registry
      # These classes should exist with singular names
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
      EXPECTED_CONFIG_CLASSES.each_key do |key|
        expect(attrs).to include(key),
                         "Expected config_class_attributes to include :#{key}"
      end
    end

    it 'base_key_attributes does not include config class attributes' do
      base = OptionConfigs::ExtraOptions.base_key_attributes
      config_attrs = OptionConfigs::ExtraOptions.config_class_attributes
      overlap = base & config_attrs
      expect(overlap).to be_empty,
                         "base_key_attributes should not overlap config_class_attributes, but found: #{overlap}"
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
  # IfCondition configuration class
  # ──────────────────────────────────────────────────────────────
  describe 'IfCondition' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::IfCondition }

    it 'exists under ExtraOptionConfigs namespace' do
      expect(klass).to be_a Class
    end

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:conditions)
      expect(klass.direct_types[:conditions]).to eq(:hash)
    end

    it 'stores entire hash as single conditions attribute' do
      instance = klass.new(always: true, user_is_creator: true)
      expect(instance.conditions).to eq(always: true, user_is_creator: true)
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'returns not blank when initialized with data' do
      instance = klass.new(always: true)
      expect(instance).not_to be_blank
    end

    it 'symbolizes keys on initialization' do
      instance = klass.new('always' => true)
      expect(instance.conditions).to have_key(:always)
    end

    it 'handles nil initialization' do
      instance = klass.new(nil)
      expect(instance.conditions).to eq({})
      expect(instance).to be_blank
    end

    it 'supports symbolize_keys for backward compatibility' do
      instance = klass.new(always: true, never: false)
      expect(instance.symbolize_keys).to eq(always: true, never: false)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # TriggerTasks configuration class
  # ──────────────────────────────────────────────────────────────
  describe 'TriggerTasks' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::TriggerTasks }

    it 'exists under ExtraOptionConfigs namespace' do
      expect(klass).to be_a Class
    end

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:tasks)
      expect(klass.direct_types[:tasks]).to eq(:hash)
    end

    it 'stores entire hash as single tasks attribute' do
      instance = klass.new(notify: { type: 'email' }, update_this: { field: 'val' })
      expect(instance.tasks).to eq(notify: { type: 'email' }, update_this: { field: 'val' })
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'handles nil initialization' do
      instance = klass.new(nil)
      expect(instance.tasks).to eq({})
      expect(instance).to be_blank
    end

    it 'symbolizes keys on initialization' do
      instance = klass.new('notify' => { 'type' => 'email' })
      expect(instance.tasks).to have_key(:notify)
    end

    it 'supports symbolize_keys for backward compatibility' do
      instance = klass.new(notify: { type: 'email' })
      expect(instance.symbolize_keys).to eq(notify: { type: 'email' })
    end

    # Array support for save_trigger values (on_create, on_update, etc.)
    it 'stores array value as tasks when initialized with an array' do
      arr = [{ notify: { type: 'email' } }, { update_this: { field: 'val' } }]
      instance = klass.new(arr)
      expect(instance.tasks).to eq(arr)
    end

    it 'returns not blank when initialized with a non-empty array' do
      instance = klass.new([{ notify: { type: 'email' } }])
      expect(instance).not_to be_blank
    end

    it 'returns blank when initialized with an empty array' do
      instance = klass.new([])
      expect(instance).to be_blank
    end

    it 'symbolize_keys returns the array as-is when tasks is an array' do
      arr = [{ notify: { type: 'email' } }]
      instance = klass.new(arr)
      expect(instance.symbolize_keys).to eq(arr)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # BatchTrigger converted to BaseConfiguration with TriggerTasks
  # ──────────────────────────────────────────────────────────────
  describe 'BatchTrigger (converted to BaseConfiguration)' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::BatchTrigger }

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares on_record as a typed attribute with TriggerTasks type' do
      expect(klass.option_types[:typed]).to include(:on_record)
      expect(klass.typed_attribute_types[:on_record]).to eq(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
    end

    it 'initializes on_record as a TriggerTasks instance from hash' do
      instance = klass.new(on_record: { notify: { type: 'email' } })
      expect(instance.on_record).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_record.tasks).to eq(notify: { type: 'email' })
    end

    it 'initializes on_record as blank TriggerTasks when not provided' do
      instance = klass.new({})
      expect(instance.on_record).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_record).to be_blank
    end

    it 'supports hash-like bracket access for on_record' do
      instance = klass.new(on_record: { action: 'process' })
      expect(instance[:on_record]).to be_a(Hash)
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
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
      # Label uses configure_direct type: :string
      label_klass = OptionConfigs::ExtraOptionConfigs::Label
      expect(label_klass.option_types[:direct]).to be_present
    end

    it 'Fields declares configure_direct type: :array' do
      fields_klass = OptionConfigs::ExtraOptionConfigs::Fields
      expect(fields_klass.option_types[:direct]).to include(:fields)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # CreatableIf, EditableIf, ShowableIf (split from AccessIf)
  # Note: detailed conversion tests are in 'if_condition classes (converted to BaseConfiguration)' section above
  # ──────────────────────────────────────────────────────────────
  describe 'if_condition classes (split from AccessIf)' do
    %i[CreatableIf EditableIf ShowableIf].each do |class_name|
      context "#{class_name}" do
        let(:klass) { "OptionConfigs::ExtraOptionConfigs::#{class_name}".constantize }

        it 'exists under ExtraOptionConfigs namespace' do
          expect(klass).to be_a Class
        end

        it 'uses configure_direct with type :hash' do
          expect(klass.option_types[:direct]).to be_present
        end
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # SaveTrigger converted to BaseConfiguration with TriggerTasks
  # ──────────────────────────────────────────────────────────────
  describe 'SaveTrigger (converted to BaseConfiguration)' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::SaveTrigger }

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares all trigger keys as typed attributes with TriggerTasks type' do
      %i[on_create on_update on_save on_upload on_disable before_save].each do |key|
        expect(klass.option_types[:typed]).to include(key),
                                              "Expected option_types[:typed] to include :#{key}"
        expect(klass.typed_attribute_types[key]).to eq(OptionConfigs::ExtraOptionConfigs::TriggerTasks),
                                                    "Expected typed_attribute_types[:#{key}] to be TriggerTasks"
      end
    end

    it 'initializes trigger keys as TriggerTasks instances' do
      instance = klass.new(on_create: [{ notify: { type: 'email' } }])
      expect(instance.on_create).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_create.tasks).to eq([{ notify: { type: 'email' } }])
    end

    it 'defaults missing trigger keys to blank TriggerTasks' do
      instance = klass.new({})
      expect(instance.on_create).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_create).to be_blank
      expect(instance.on_upload).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_upload).to be_blank
    end

    it 'supports hash-like bracket access for trigger keys' do
      instance = klass.new(on_create: [{ notify: { type: 'email' } }])
      expect(instance[:on_create]).to be_a(Array)
    end

    it 'cascades on_save into on_create and on_update' do
      instance = klass.new(on_save: { notify: { type: 'email' } })
      expect(instance.on_create.tasks).to be_an Array
      expect(instance.on_create.tasks.length).to eq 1
      expect(instance.on_update.tasks).to be_an Array
      expect(instance.on_update.tasks.length).to eq 1
    end

    it 'appends on_save to existing on_create and on_update' do
      instance = klass.new(
        on_save: { notify: { type: 'email' } },
        on_create: { create_action: { type: 'special' } }
      )
      expect(instance.on_create.tasks).to be_an Array
      expect(instance.on_create.tasks.length).to eq 2
      expect(instance.on_update.tasks).to be_an Array
      expect(instance.on_update.tasks.length).to eq 1
    end

    it 'validates keys against ValidSaveTriggerTriggers' do
      instance = klass.new(on_invalid_trigger: { something: true })
      expect(instance.config_errors).not_to be_empty
      err = instance.config_errors.find { |e| e[:type] == :save_trigger }
      expect(err).to be_present
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end
  end

  # ──────────────────────────────────────────────────────────────
  # ViewOptions converted to BaseConfiguration (simple direct hash)
  # ──────────────────────────────────────────────────────────────
  describe 'ViewOptions (converted to BaseConfiguration)' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::ViewOptions }

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:view_options)
    end

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
  end

  # ──────────────────────────────────────────────────────────────
  # Filestore converted to BaseConfiguration (simple direct hash)
  # ──────────────────────────────────────────────────────────────
  describe 'Filestore (converted to BaseConfiguration)' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::Filestore }

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:filestore)
    end

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

  # ──────────────────────────────────────────────────────────────
  # ConfigTrigger converted to BaseConfiguration
  # ──────────────────────────────────────────────────────────────
  describe 'ConfigTrigger (converted to BaseConfiguration)' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::ConfigTrigger }

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares on_define as a typed attribute with TriggerTasks type' do
      expect(klass.option_types[:typed]).to include(:on_define)
      expect(klass.typed_attribute_types[:on_define]).to eq(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
    end

    it 'wraps non-array on_define in an array' do
      instance = klass.new(on_define: { action: 'do_something' })
      expect(instance.on_define).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_define.tasks).to be_an Array
      expect(instance.on_define.tasks.length).to eq 1
    end

    it 'preserves array on_define' do
      instance = klass.new(on_define: [{ action: 'first' }, { action: 'second' }])
      expect(instance.on_define).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_define.tasks).to be_an Array
      expect(instance.on_define.tasks.length).to eq 2
    end

    it 'defaults on_define to blank TriggerTasks when not provided' do
      instance = klass.new({})
      expect(instance.on_define).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.on_define).to be_blank
    end

    it 'supports hash-like bracket access' do
      instance = klass.new(on_define: [{ action: 'test' }])
      expect(instance[:on_define]).to be_a(Array)
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end
  end

  # ──────────────────────────────────────────────────────────────
  # SaveAction converted to BaseConfiguration (simple direct hash with cascade)
  # ──────────────────────────────────────────────────────────────
  describe 'SaveAction (converted to BaseConfiguration)' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::SaveAction }

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:save_action)
    end

    it 'cascades on_save to on_create and on_update' do
      instance = klass.new(on_save: { label: 'Saved' })
      expect(instance.save_action[:on_create]).to eq(label: 'Saved')
      expect(instance.save_action[:on_update]).to eq(label: 'Saved')
    end

    it 'merges on_save into existing on_create and on_update' do
      instance = klass.new(on_save: { label: 'Default', notify: true }, on_create: { label: 'Created' })
      expect(instance.save_action[:on_create][:label]).to eq 'Created'
      expect(instance.save_action[:on_create][:notify]).to eq true
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'symbolizes keys for backward compatibility' do
      instance = klass.new(label: 'Test')
      expect(instance.symbolize_keys).to eq(label: 'Test')
    end
  end

  # ──────────────────────────────────────────────────────────────
  # ValidIf converted to BaseConfiguration (direct hash with cascade + validation)
  # ──────────────────────────────────────────────────────────────
  describe 'ValidIf (converted to BaseConfiguration)' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::ValidIf }

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:valid_if)
    end

    it 'cascades on_save to on_create and on_update' do
      instance = klass.new(on_save: { all: { this: { test1: 'is not null' } } })
      expect(instance.valid_if[:on_create]).to eq(instance.valid_if[:on_save])
      expect(instance.valid_if[:on_update]).to eq(instance.valid_if[:on_save])
    end

    it 'validates keys against ValidValidIfTriggers' do
      instance = klass.new(on_invalid_key: { always: true })
      expect(instance.config_errors).not_to be_empty
      err = instance.config_errors.find { |e| e[:type] == :valid_if }
      expect(err).to be_present
    end

    it 'returns blank when initialized with empty hash' do
      instance = klass.new({})
      expect(instance).to be_blank
    end

    it 'symbolizes keys for backward compatibility' do
      instance = klass.new(on_save: { always: true })
      expect(instance.symbolize_keys).to have_key(:on_save)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # SetVariable converted to BaseConfiguration (direct array with validation)
  # ──────────────────────────────────────────────────────────────
  describe 'SetVariable (converted to BaseConfiguration)' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::SetVariable }

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :array' do
      expect(klass.option_types[:direct]).to include(:set_variables)
    end

    it 'stores valid array entries' do
      instance = klass.new([{ name: 'var1', value: 'val1' }])
      expect(instance.set_variables).to be_an Array
      expect(instance.set_variables.length).to eq 1
      expect(instance.set_variables[0][:name]).to eq 'var1'
    end

    it 'reports error when value is not an array' do
      instance = klass.new(name: 'var1', value: 'val1')
      expect(instance.config_errors).not_to be_empty
    end

    it 'filters out invalid entries' do
      instance = klass.new([{ name: 'valid', value: 'val' }, { no_name: 'invalid' }])
      expect(instance.set_variables.length).to eq 1
    end

    it 'returns blank when initialized with nil' do
      instance = klass.new(nil)
      expect(instance).to be_blank
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Fields (converted to BaseConfiguration)
  # ──────────────────────────────────────────────────────────────
  describe 'Fields (converted to BaseConfiguration)' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::Fields }

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :array' do
      expect(klass.option_types[:direct]).to include(:fields)
    end

    it 'stores the array as fields attribute' do
      instance = klass.new(%w[field1 field2])
      expect(instance.fields).to eq %w[field1 field2]
    end

    it 'defaults to empty array when initialized with nil' do
      instance = klass.new(nil)
      expect(instance.fields).to eq []
    end

    it 'returns blank when initialized with empty array' do
      instance = klass.new([])
      expect(instance).to be_blank
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Label (converted to BaseConfiguration)
  # ──────────────────────────────────────────────────────────────
  describe 'Label (converted to BaseConfiguration)' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::Label }

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :string' do
      expect(klass.option_types[:direct]).to include(:label)
    end

    it 'stores the string as label attribute' do
      instance = klass.new('My Label')
      expect(instance.label).to eq 'My Label'
    end

    it 'defaults to empty string when initialized with nil' do
      instance = klass.new(nil)
      expect(instance.label).to eq ''
    end

    it 'uses prepare_config to default to humanized name from parent' do
      expect(klass).to respond_to(:prepare_config)
    end

    it 'integration: defaults label to humanized name when not specified' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
      YAML
      # Label uses store_processed_value?, so eo.label is a plain string
      expect(eo.label).to eq 'Default'
    end

    it 'integration: preserves explicit label' do
      eo = config_for(<<~YAML)
        default:
          label: Custom Label
          fields:
            - test1
      YAML
      expect(eo.label).to eq 'Custom Label'
    end
  end

  # ──────────────────────────────────────────────────────────────
  # CreatableIf, EditableIf, ShowableIf (converted to BaseConfiguration)
  # ──────────────────────────────────────────────────────────────
  describe 'if_condition classes (converted to BaseConfiguration)' do
    %i[CreatableIf EditableIf ShowableIf].each do |class_name|
      context "#{class_name}" do
        let(:klass) { "OptionConfigs::ExtraOptionConfigs::#{class_name}".constantize }
        let(:attr_name) { class_name.to_s.underscore.to_sym }

        it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
          expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
        end

        it 'does not inherit from ConfigBase' do
          expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
        end

        it 'declares configure_direct with type :hash' do
          expect(klass.option_types[:direct]).to include(attr_name)
        end

        it 'stores the hash as the attribute' do
          instance = klass.new(always: true)
          expect(instance.send(attr_name)).to eq(always: true)
        end

        it 'supports hash-like bracket access' do
          instance = klass.new(always: true)
          expect(instance[:always]).to eq true
        end

        it 'defaults to empty hash when initialized with nil' do
          instance = klass.new(nil)
          expect(instance.send(attr_name)).to eq({})
          expect(instance).to be_blank
        end
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Embed (converted to BaseConfiguration)
  # ──────────────────────────────────────────────────────────────
  describe 'Embed (converted to BaseConfiguration)' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::Embed }

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:embed)
    end

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

  # ──────────────────────────────────────────────────────────────
  # FieldConfigs (converted to BaseConfiguration)
  # ──────────────────────────────────────────────────────────────
  describe 'FieldConfigs (converted to BaseConfiguration)' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::FieldConfigs }

    it 'inherits from ExtraOptionConfigs::BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::BaseConfiguration)
    end

    it 'does not inherit from ConfigBase' do
      expect(klass.ancestors).not_to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:field_configs)
    end

    it 'stores the hash as field_configs attribute' do
      instance = klass.new(test1: { caption_before: 'Test' })
      expect(instance.field_configs).to eq(test1: { caption_before: 'Test' })
    end

    it 'defaults to empty hash when initialized with nil' do
      instance = klass.new(nil)
      expect(instance.field_configs).to eq({})
    end
  end

  # ──────────────────────────────────────────────────────────────
  # References (converted to BaseConfiguration)
  # ──────────────────────────────────────────────────────────────
  describe 'References (converted to BaseConfiguration)' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::References }

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
  end

  # Config classes that still use ConfigBase pattern
  CONFIGBASE_CLASSES = {}.freeze

  # Config classes that use the field-keyed BaseConfiguration pattern
  FIELD_KEYED_CLASSES = %i[CaptionBefore Labels DialogBefore ShowIf FieldOptions DbConfigs PresetFields].freeze

  # Config classes converted to BaseConfiguration with typed or direct attributes
  TYPED_CONFIG_CLASSES = %i[
    BatchTrigger SaveTrigger ViewOptions Filestore ConfigTrigger SaveAction ValidIf SetVariable
    Fields Label CreatableIf EditableIf ShowableIf Embed FieldConfigs References
  ].freeze

  # ──────────────────────────────────────────────────────────────
  # Configuration classes: existence, inheritance, managed_attributes
  # ──────────────────────────────────────────────────────────────
  describe 'ConfigBase configuration classes exist with correct structure' do
    CONFIGBASE_CLASSES.each do |class_name, expected_attributes|
      context "#{class_name}" do
        let(:klass) { "OptionConfigs::ExtraOptionConfigs::#{class_name}".constantize }

        it 'exists under OptionConfigs::ExtraOptionConfigs namespace' do
          expect(klass).to be_a Class
        end

        it 'inherits from ConfigBase' do
          expect(klass.ancestors).to include(OptionConfigs::ExtraOptionConfigs::ConfigBase)
        end

        it "declares managed attributes #{expected_attributes}" do
          expected_attributes.each do |attr|
            expect(klass.managed_attributes).to include(attr),
                                                "Expected #{class_name}.managed_attributes to include :#{attr}"
          end
        end

        it 'includes ActiveModel::Validations' do
          expect(klass.ancestors).to include(ActiveModel::Validations)
        end

        it 'responds to validators for reflection' do
          expect(klass).to respond_to(:validators)
        end
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # CaptionBefore: BaseConfiguration/NamedConfiguration pattern
  # ──────────────────────────────────────────────────────────────
  describe 'CaptionBefore uses BaseConfiguration pattern' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::CaptionBefore }

    it 'inherits from BaseConfiguration' do
      expect(klass.ancestors).to include(OptionConfigs::BaseConfiguration)
    end

    it 'defines a NamedConfiguration inner class' do
      expect(klass.const_defined?(:NamedConfiguration)).to be true
    end

    it 'NamedConfiguration inherits from BaseNamedConfiguration' do
      expect(klass::NamedConfiguration.ancestors).to include(OptionConfigs::BaseNamedConfiguration)
    end

    it 'NamedConfiguration declares caption attributes via configure_attributes' do
      expected = %i[caption edit_caption show_caption new_caption]
      expected.each do |attr|
        expect(klass::NamedConfiguration.option_types[:simple]).to include(attr)
      end
    end

    context 'initialized with a raw hash' do
      let(:raw_config) { { test1: 'Simple text', test2: { caption: 'Cap', edit_caption: 'Edit' } } }
      let(:instance) { klass.new(raw_config) }

      it 'creates named configurations for each field' do
        expect(instance.configurations).to have_key(:test1)
        expect(instance.configurations).to have_key(:test2)
      end

      it 'stores NamedConfiguration objects in configurations' do
        expect(instance.configurations[:test1]).to be_a klass::NamedConfiguration
        expect(instance.configurations[:test2]).to be_a klass::NamedConfiguration
      end

      it 'preprocesses string values into all caption modes' do
        nc = instance.configurations[:test1]
        expect(nc.caption).to be_present
        expect(nc.edit_caption).to eq nc.caption
        expect(nc.show_caption).to eq nc.caption
        expect(nc.new_caption).to eq nc.caption
      end

      it 'preserves hash values with individual mode settings' do
        nc = instance.configurations[:test2]
        expect(nc.caption).to include('Cap')
        expect(nc.edit_caption).to include('Edit')
      end

      it 'defaults new_caption to edit_caption when not specified' do
        nc = instance.configurations[:test2]
        expect(nc.new_caption).to eq nc.edit_caption
      end
    end

    context 'hash-like interface' do
      let(:raw_config) { { test1: 'Caption text' } }
      let(:instance) { klass.new(raw_config) }

      it '[] returns a NamedConfiguration for a given field' do
        expect(instance[:test1]).to be_a klass::NamedConfiguration
      end

      it '[] returns nil for missing fields' do
        expect(instance[:nonexistent]).to be_nil
      end

      it 'NamedConfiguration supports [] for attribute access' do
        nc = instance[:test1]
        expect(nc[:caption]).to eq nc.caption
        expect(nc[:edit_caption]).to eq nc.edit_caption
      end

      it 'supports keys method' do
        expect(instance.keys).to eq [:test1]
      end

      it 'supports each iteration' do
        yielded = []
        instance.each { |k, v| yielded << [k, v.class] }
        expect(yielded).to eq [[:test1, klass::NamedConfiguration]]
      end

      it 'supports blank? for empty config' do
        empty = klass.new({})
        expect(empty).to be_blank
      end

      it 'supports blank? for populated config' do
        expect(instance).not_to be_blank
      end

      it 'supports merge! with a plain hash' do
        instance.merge!(test2: { caption: 'New cap' })
        expect(instance[:test2]).to be_a klass::NamedConfiguration
        expect(instance[:test2].caption).to include('New cap')
      end

      it 'supports []= assignment' do
        instance[:test3] = { caption: 'Assigned' }
        expect(instance[:test3]).to be_a klass::NamedConfiguration
        expect(instance[:test3].caption).to include('Assigned')
      end

      it 'symbolize_keys returns a plain Hash for backward compat' do
        result = instance.symbolize_keys
        expect(result).to be_a Hash
        expect(result[:test1]).to be_a Hash
        expect(result[:test1]).to have_key(:caption)
      end
    end

    context 'JSON serialization' do
      let(:raw_config) { { test1: 'Cap text', test2: { caption: 'C', edit_caption: 'E' } } }
      let(:instance) { klass.new(raw_config) }

      it 'as_json returns a plain nested hash' do
        json = instance.as_json
        expect(json).to be_a Hash
        expect(json['test1']).to be_a Hash
        expect(json['test1']).to have_key('caption')
      end

      it 'to_json produces valid JSON matching the expected format' do
        json_str = instance.to_json
        parsed = JSON.parse(json_str)
        expect(parsed).to have_key('test1')
        expect(parsed['test1']).to have_key('caption')
      end

      it 'empty config serializes to empty JSON object' do
        empty = klass.new({})
        expect(JSON.parse(empty.to_json)).to eq({})
      end
    end

    context 'unrecognized NamedConfiguration attributes' do
      it 'reports a config warning when a field has an unrecognized attribute' do
        raw = { test1: { caption: 'Valid', bogus_attr: 'Invalid' } }
        instance = klass.new(raw)
        expect(instance.config_warnings).to be_present,
                                            'Expected config_warnings for unrecognized attribute bogus_attr'
        warning_messages = instance.config_warnings.map { |w| w[:message] }
        expect(warning_messages.any? { |m| m.include?('bogus_attr') }).to be(true),
                                                                          "Expected warning mentioning 'bogus_attr', got: #{warning_messages}"
      end

      it 'does not report warnings for valid attributes only' do
        raw = { test1: { caption: 'Cap', edit_caption: 'Edit', show_caption: 'Show', new_caption: 'New' } }
        instance = klass.new(raw)
        expect(instance.config_warnings).to be_empty,
                                            "Expected no config_warnings for valid attributes, got: #{instance.config_warnings}"
      end

      it 'does not report warnings for string values (auto-expanded)' do
        raw = { test1: 'Simple text' }
        instance = klass.new(raw)
        expect(instance.config_warnings).to be_empty,
                                            "Expected no config_warnings for string value, got: #{instance.config_warnings}"
      end

      it 'reports multiple unrecognized attributes in a single field' do
        raw = { test1: { caption: 'Valid', bad1: 'x', bad2: 'y' } }
        instance = klass.new(raw)
        warning_messages = instance.config_warnings.map { |w| w[:message] }
        expect(warning_messages.any? { |m| m.include?('bad1') }).to be(true)
        expect(warning_messages.any? { |m| m.include?('bad2') }).to be(true)
      end

      it 'reports unrecognized attributes across multiple fields' do
        raw = { field1: { caption: 'OK', nope1: 'x' }, field2: { bogus2: 'y' } }
        instance = klass.new(raw)
        warning_messages = instance.config_warnings.map { |w| w[:message] }
        expect(warning_messages.any? { |m| m.include?('nope1') }).to be(true)
        expect(warning_messages.any? { |m| m.include?('bogus2') }).to be(true)
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Field-keyed classes inheriting ExtraOptionConfigs::BaseConfiguration
  # ──────────────────────────────────────────────────────────────
  describe 'Field-keyed BaseConfiguration classes' do
    FIELD_KEYED_CLASSES.each do |class_name|
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

    context 'Labels stores plain string values' do
      let(:instance) { OptionConfigs::ExtraOptionConfigs::Labels.new(field1: 'Label One', field2: 'Label Two') }

      it 'returns string values via bracket access' do
        expect(instance[:field1]).to eq 'Label One'
        expect(instance[:field2]).to eq 'Label Two'
      end

      it 'symbolize_keys returns a plain Hash' do
        expect(instance.symbolize_keys).to eq(field1: 'Label One', field2: 'Label Two')
      end
    end

    context 'DialogBefore creates NamedConfiguration for valid entries' do
      before do
        create_admin
        Admin::MessageTemplate.create!(
          name: 'test_dialog',
          message_type: :dialog,
          template_type: :content,
          template: '<p>test</p>',
          current_admin: @admin
        )
      end

      let(:instance) { OptionConfigs::ExtraOptionConfigs::DialogBefore.new(field1: 'test_dialog') }

      it 'converts string to NamedConfiguration with name attribute' do
        nc = instance[:field1]
        expect(nc).to be_a OptionConfigs::BaseNamedConfiguration
        expect(nc[:name]).to eq 'test_dialog'
      end

      it 'reports warning for missing template' do
        instance = OptionConfigs::ExtraOptionConfigs::DialogBefore.new(field1: 'nonexistent')
        expect(instance.config_warnings).not_to be_empty
      end
    end

    context 'ShowIf stores arbitrary condition hashes directly' do
      let(:instance) { OptionConfigs::ExtraOptionConfigs::ShowIf.new(field1: { other_field: 'value' }) }

      it 'returns condition hashes via bracket access' do
        expect(instance[:field1]).to eq(other_field: 'value')
      end

      it 'symbolize_keys returns plain Hash of condition hashes' do
        expect(instance.symbolize_keys).to eq(field1: { other_field: 'value' })
      end
    end

    context 'FieldOptions preprocesses alt_options arrays' do
      let(:instance) do
        OptionConfigs::ExtraOptionConfigs::FieldOptions.new(
          field1: { edit_as: { alt_options: %w[ChoiceA ChoiceB] } }
        )
      end

      it 'converts alt_options Array to Hash' do
        ao = instance[:field1][:edit_as][:alt_options]
        expect(ao).to be_a Hash
        expect(ao[:ChoiceA]).to eq 'choicea'
      end
    end

    context 'DbConfigs stores column configs directly' do
      let(:instance) { OptionConfigs::ExtraOptionConfigs::DbConfigs.new(col1: 'type_a') }

      it 'returns values and symbolize_keys produces plain Hash' do
        expect(instance[:col1]).to eq 'type_a'
        expect(instance.symbolize_keys).to eq(col1: 'type_a')
      end
    end

    context 'PresetFields stores preset values directly' do
      let(:instance) { OptionConfigs::ExtraOptionConfigs::PresetFields.new(field1: 'default_val') }

      it 'returns values via bracket access' do
        expect(instance[:field1]).to eq 'default_val'
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # ExtraOptions integration: config_instances
  # ──────────────────────────────────────────────────────────────
  describe 'ExtraOptions integration' do
    it 'stores config_instances after initialization (empty since all converted to BaseConfiguration)' do
      eo = config_for(<<~YAML)
        default:
          label: Integration Test
          fields:
            - test1
      YAML

      expect(eo).to respond_to(:config_instances)
      expect(eo.config_instances).to be_a Hash
      # All classes are now BaseConfiguration — config_instances should be empty
      expect(eo.config_instances).to be_empty
    end

    it 'no ConfigBase classes remain — config_instances is empty' do
      eo = config_for(<<~YAML)
        default:
          label: Full Config
          fields:
            - test1
      YAML

      expect(eo.config_instances).to be_empty

      # Field-keyed classes should NOT be in config_instances
      FIELD_KEYED_CLASSES.each do |class_name|
        key = class_name.to_s.underscore.to_sym
        expect(eo.config_instances).not_to have_key(key),
                                           "#{class_name} should not be in config_instances (stored directly as attribute)"
      end

      # Typed/direct config classes should NOT be in config_instances (stored directly as BaseConfiguration attribute)
      TYPED_CONFIG_CLASSES.each do |class_name|
        key = EXPECTED_CONFIG_CLASSES.key(class_name)
        expect(eo.config_instances).not_to have_key(key),
                                           "#{class_name} should not be in config_instances (stored directly as attribute)"
      end
    end

    it 'caption_before is stored directly as a CaptionBefore instance on ExtraOptions' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          caption_before:
            test1: Direct storage test
      YAML

      expect(eo.caption_before).to be_a OptionConfigs::ExtraOptionConfigs::CaptionBefore
      expect(eo.caption_before[:test1]).to be_present
    end

    it 'field-keyed classes are stored directly as BaseConfiguration instances' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          labels:
            test1: Test Label
          show_if:
            test1:
              other_field: val
          field_options:
            test1:
              no_downcase: true
          db_configs:
            test1: some_value
          preset_fields:
            test1: preset_val
      YAML

      expect(eo.labels).to be_a OptionConfigs::ExtraOptionConfigs::BaseConfiguration
      expect(eo.show_if).to be_a OptionConfigs::ExtraOptionConfigs::BaseConfiguration
      expect(eo.field_options).to be_a OptionConfigs::ExtraOptionConfigs::BaseConfiguration
      expect(eo.db_configs).to be_a OptionConfigs::ExtraOptionConfigs::BaseConfiguration
      expect(eo.preset_fields).to be_a OptionConfigs::ExtraOptionConfigs::BaseConfiguration
    end

    it 'BaseConfiguration attribute values are accessible on ExtraOptions' do
      eo = config_for(<<~YAML)
        default:
          label: Matching Test
          fields:
            - test1
            - test2
          labels:
            test1: Test One
          view_options:
            data_attribute: test1
          preset_fields:
            test1: preset_val
      YAML

      # Label and Fields use store_processed_value?, so stored as plain string/array
      expect(eo.label).to eq 'Matching Test'
      expect(eo.fields).to eq %w[test1 test2]
      # Field-keyed classes are stored directly (not in config_instances)
      expect(eo.labels[:test1]).to eq 'Test One'
      # ViewOptions is a BaseConfiguration instance (not store_processed_value?)
      expect(eo.view_options).to be_a OptionConfigs::ExtraOptionConfigs::ViewOptions
      expect(eo.view_options[:data_attribute]).to eq 'test1'
      expect(eo.preset_fields[:test1]).to eq 'preset_val'
    end

    it 'access_if classes store processed hash values (via store_processed_value?)' do
      eo = config_for(<<~YAML)
        default:
          creatable_if:
            always: true
          editable_if:
            never: true
          showable_if:
            user_is_creator: true
      YAML

      # store_processed_value? means the raw hash is stored, not the BaseConfiguration object
      expect(eo.creatable_if).to be_a Hash
      expect(eo.creatable_if[:always]).to eq true
      expect(eo.editable_if).to be_a Hash
      expect(eo.editable_if[:never]).to eq true
      expect(eo.showable_if).to be_a Hash
      expect(eo.showable_if[:user_is_creator]).to eq true
    end

    it 'caption_before values match between CaptionBefore instance and ExtraOptions' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          caption_before:
            test1: Simple caption text
      YAML

      cb = eo.caption_before
      expect(cb).to be_a OptionConfigs::ExtraOptionConfigs::CaptionBefore
      expect(cb[:test1][:caption]).to be_present
    end

    it 'save_trigger is stored directly as a SaveTrigger instance' do
      eo = config_for(<<~YAML)
        default:
          save_trigger:
            on_save:
              notify:
                type: email
      YAML

      expect(eo.save_trigger).to be_a OptionConfigs::ExtraOptionConfigs::SaveTrigger
      expect(eo.save_trigger[:on_create]).to be_a Array
    end

    it 'valid_if is stored directly as a ValidIf BaseConfiguration instance' do
      eo = config_for(<<~YAML)
        default:
          valid_if:
            on_save:
              all:
                this:
                  test1: is not null
      YAML

      expect(eo.valid_if).to be_a OptionConfigs::ExtraOptionConfigs::ValidIf
      expect(eo.valid_if[:on_create]).to be_present
    end
  end

  # ──────────────────────────────────────────────────────────────
  # config_obj mutation is properly handled outside config classes
  # ──────────────────────────────────────────────────────────────
  describe 'config_obj mutation handling' do
    it 'sets config_obj.db_columns from db_configs after DbConfigs runs' do
      eo = config_for(<<~YAML)
        default:
          db_configs:
            some_column: some_value
      YAML

      # db_columns should be set on the config_obj (DynamicModel)
      expect(@dm.db_columns).to eq(some_column: 'some_value')
    end
  end

  # ──────────────────────────────────────────────────────────────
  # ActiveModel::Validations integration (run_validations bridge)
  # ──────────────────────────────────────────────────────────────
  # Tests for the run_validations bridge that calls valid? after
  # setup_named_configurations and bridges ActiveModel::Validations
  # errors into config_errors via failed_config. Also tests the
  # TypedAttributeValidator custom validator that checks typed
  # attributes have the correct type.
  # ──────────────────────────────────────────────────────────────
  describe 'ActiveModel::Validations integration' do
    it 'errors is ActiveModel::Errors, not a plain Array' do
      instance = OptionConfigs::ExtraOptionConfigs::BaseConfiguration.new({})
      expect(instance.errors).to be_a(ActiveModel::Errors)
    end

    it 'validates declarations produce config_errors when value is blank' do
      test_class = Class.new(OptionConfigs::ExtraOptionConfigs::BaseConfiguration) do
        configure_direct :test_attr, type: :string
        validates :test_attr, presence: true
      end

      instance = test_class.new({})
      expect(instance.config_errors).not_to be_empty
      messages = instance.config_errors.map { |e| e[:message] }
      expect(messages.join(' ')).to match(/test_attr.*blank|can't be blank/i)
    end

    it 'valid config produces no config_errors from validates' do
      test_class = Class.new(OptionConfigs::ExtraOptionConfigs::BaseConfiguration) do
        configure_direct :test_attr, type: :string
        validates :test_attr, presence: true

        def setup_named_configurations
          self.test_attr = 'a valid value'
        end
      end

      instance = test_class.new({})
      expect(instance.config_errors).to be_empty
    end

    it 'TypedAttributeValidator catches wrong type' do
      test_class = Class.new(OptionConfigs::ExtraOptionConfigs::BaseConfiguration) do
        configure_typed_attribute :my_typed, type: OptionConfigs::ExtraOptionConfigs::TriggerTasks
        validates :my_typed, 'validates/typed_attribute': true

        def setup_named_configurations
          setup_all_options_typed(hash_configuration)
        end
      end

      instance = test_class.new({})
      # Manually assign wrong type after initialization
      instance.my_typed = 'wrong'
      instance.valid?
      expect(instance.errors[:my_typed]).not_to be_empty
      expect(instance.errors[:my_typed].join(' ')).to match(/must be a.*TriggerTasks.*got String/)
    end

    it 'TypedAttributeValidator passes correct type' do
      test_class = Class.new(OptionConfigs::ExtraOptionConfigs::BaseConfiguration) do
        configure_typed_attribute :my_typed, type: OptionConfigs::ExtraOptionConfigs::TriggerTasks
        validates :my_typed, 'validates/typed_attribute': true

        def setup_named_configurations
          setup_all_options_typed(hash_configuration)
        end
      end

      instance = test_class.new(my_typed: { notify: { type: 'email' } })
      expect(instance.my_typed).to be_a(OptionConfigs::ExtraOptionConfigs::TriggerTasks)
      expect(instance.valid?).to be true
      expect(instance.errors[:my_typed]).to be_empty
    end

    it 'TypedAttributeValidator allows nil' do
      test_class = Class.new(OptionConfigs::ExtraOptionConfigs::BaseConfiguration) do
        configure_typed_attribute :my_typed, type: OptionConfigs::ExtraOptionConfigs::TriggerTasks
        validates :my_typed, 'validates/typed_attribute': true

        def setup_named_configurations
          # Don't set my_typed — leave it nil
        end
      end

      instance = test_class.new({})
      expect(instance.my_typed).to be_nil
      expect(instance.valid?).to be true
      expect(instance.errors[:my_typed]).to be_empty
    end

    it 'full integration: BatchTrigger subclass with validates produces config_errors on empty config' do
      test_class = Class.new(OptionConfigs::ExtraOptionConfigs::BatchTrigger) do
        validates :on_record, presence: true
      end

      instance = test_class.new({})
      expect(instance.config_errors).not_to be_empty
      messages = instance.config_errors.map { |e| e[:message] }
      expect(messages.join(' ')).to match(/on_record.*blank|can't be blank/i)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # validate callbacks (migrated from manual failed_config calls)
  # ──────────────────────────────────────────────────────────────
  # Phase 3 of issue #986: Verify that validation logic in ValidIf,
  # SaveTrigger, and SetVariable subclasses produces the expected
  # config_errors and ActiveModel::Errors when given invalid input.
  # Tests 1-7 verify config_errors (pass now, pass after migration).
  # Tests 8-10 verify ActiveModel errors (FAIL now, pass after migration).
  describe 'validate callbacks' do
    describe 'ValidIf' do
      it 'with invalid keys has errors on :valid_if' do
        instance = OptionConfigs::ExtraOptionConfigs::ValidIf.new(on_invalid_key: { always: true })
        expect(instance.config_errors).not_to be_empty
        err = instance.config_errors.find { |e| e[:type] == :valid_if }
        expect(err).to be_present
        expect(err[:message]).to match(/invalid keys/)
      end

      it 'with valid keys has no validation errors' do
        instance = OptionConfigs::ExtraOptionConfigs::ValidIf.new(on_save: { all: { this: { field: 'is not null' } } })
        expect(instance.config_errors).to be_empty
      end

      it 'with invalid keys has ActiveModel errors' do
        instance = OptionConfigs::ExtraOptionConfigs::ValidIf.new(on_invalid_key: { always: true })
        expect(instance.errors[:valid_if]).not_to be_empty
      end
    end

    describe 'SaveTrigger' do
      it 'with invalid keys has errors on :save_trigger' do
        instance = OptionConfigs::ExtraOptionConfigs::SaveTrigger.new(on_invalid_trigger: { something: true })
        expect(instance.config_errors).not_to be_empty
        err = instance.config_errors.find { |e| e[:type] == :save_trigger }
        expect(err).to be_present
        expect(err[:message]).to match(/invalid keys/)
      end

      it 'with valid keys has no validation errors' do
        instance = OptionConfigs::ExtraOptionConfigs::SaveTrigger.new(on_create: [{ notify: { type: 'email' } }])
        expect(instance.config_errors).to be_empty
      end

      it 'with invalid keys has ActiveModel errors' do
        instance = OptionConfigs::ExtraOptionConfigs::SaveTrigger.new(on_invalid_trigger: { something: true })
        expect(instance.errors[:save_trigger]).not_to be_empty
      end
    end

    describe 'SetVariable' do
      it 'with non-array input has errors on :set_variables' do
        instance = OptionConfigs::ExtraOptionConfigs::SetVariable.new({ name: 'var1', value: 'val1' })
        expect(instance.config_errors).not_to be_empty
        err = instance.config_errors.find { |e| e[:type] == :set_variables }
        expect(err).to be_present
        expect(err[:message]).to match(/must be an array/)
      end

      it 'with invalid entries has errors on :set_variables' do
        instance = OptionConfigs::ExtraOptionConfigs::SetVariable.new([{ bad_key: 'test' }])
        expect(instance.config_errors).not_to be_empty
        err = instance.config_errors.find { |e| e[:type] == :set_variables }
        expect(err).to be_present
        expect(err[:message]).to match(/must have 'name' and 'value' keys/)
      end

      it 'with valid entries has no validation errors' do
        instance = OptionConfigs::ExtraOptionConfigs::SetVariable.new([{ name: 'v', value: 'x' }])
        expect(instance.config_errors).to be_empty
      end

      it 'with non-array has ActiveModel errors' do
        instance = OptionConfigs::ExtraOptionConfigs::SetVariable.new({ name: 'var1', value: 'val1' })
        expect(instance.errors[:set_variables]).not_to be_empty
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # References.reprocess (#986)
  # Verify that References.reprocess can re-run prepare_config on an
  # already-initialized ExtraOptions instance after its references
  # attribute has been mutated. This method does not exist yet and
  # these tests are expected to FAIL in the red phase.
  # ──────────────────────────────────────────────────────────────
  describe 'References.reprocess' do
    let(:references_class) { OptionConfigs::ExtraOptionConfigs::References }

    it 'exists as a class method on References' do
      expect(references_class).to respond_to(:reprocess)
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

      # Initial references should have been processed (singular key, metadata populated)
      expect(eo.references).to be_a(Hash)
      initial_ref = eo.references[:player_contact]
      expect(initial_ref).to be_present
      expect(initial_ref[:player_contact][:to_record_label]).to be_present

      # Mutate references with a raw hash using plural keys (simulating post-init mutation)
      eo.references = { player_contacts: { from: 'this', add: 'many' } }

      # Call reprocess to re-run prepare_config on the mutated value
      references_class.reprocess(eo)

      # After reprocessing, plural keys should be singularized
      expect(eo.references).to be_a(Hash)
      reprocessed_ref = eo.references[:player_contact]
      expect(reprocessed_ref).to be_present, 'Expected plural key :player_contacts to be singularized to :player_contact'
      expect(reprocessed_ref[:player_contact][:to_record_label]).to be_present
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Old clean_ methods removed (#986)
  # Confirm that the 21 legacy clean_ methods have been removed from
  # ExtraOptions. They were replaced by config_class_registry classes.
  # ──────────────────────────────────────────────────────────────
  describe 'old clean_ methods removed' do
    let(:removed_clean_methods) do
      %i[
        clean_label_def
        clean_caption_before_def
        clean_dialog_before_def
        clean_labels_def
        clean_show_if_def
        clean_save_action_def
        clean_view_options_def
        clean_db_configs_def
        clean_fields_def
        clean_field_options_def
        clean_filestore_def
        clean_access_if_def
        clean_valid_if_def
        clean_embed_def
        clean_references_def
        clean_save_triggers
        clean_batch_triggers
        clean_config_triggers
        clean_preset_fields
        clean_set_variables_def
        clean_field_configs
      ]
    end

    it 'no longer defines any clean_ instance methods' do
      removed_clean_methods.each do |method_name|
        expect(OptionConfigs::ExtraOptions.method_defined?(method_name, false))
          .to be(false), "Expected #{method_name} to be removed from ExtraOptions"
      end
    end

    it 'still initializes correctly without clean_ methods' do
      yaml = <<~YAML
        default:
          label: Test
          fields:
            - test_field
          caption_before:
            test_field: A Caption
          show_if:
            test_field:
              test_field2: value
          view_options:
            show_result_options: true
      YAML
      eo = config_for(yaml)
      expect(eo.label).to eq('Test')
      expect(eo.caption_before).to be_present
      expect(eo.show_if).to be_present
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Validate callbacks for remaining classes (#986)
  #
  # RED PHASE: These tests verify that DialogBefore, Embed,
  # References, and FieldConfigs use ActiveModel validate callbacks
  # (errors.add) instead of calling failed_config directly.
  #
  # Currently these classes report errors via failed_config in
  # prepare_config or add_named_configuration. After migration,
  # they should populate ActiveModel errors on the INSTANCE,
  # which run_validations bridges into config_errors.
  #
  # These tests WILL FAIL until the production code is migrated.
  # ──────────────────────────────────────────────────────────────
  describe 'validate callbacks for remaining classes (#986)' do
    describe 'DialogBefore' do
      let(:klass) { OptionConfigs::ExtraOptionConfigs::DialogBefore }

      it 'produces ActiveModel errors when value is an invalid type' do
        # 12345 is neither String nor Hash — should be rejected
        instance = klass.new(test_field: 12_345)
        expect(instance.errors.any? { |e| e.attribute == :dialog_before }).to be(true),
                                                                              'Expected ActiveModel error on :dialog_before for invalid type, but none found'
      end

      it 'produces ActiveModel errors (warning level) when template does not exist' do
        instance = klass.new(test_field: { name: 'nonexistent_template_xyz_999' })
        # After migration, missing template should produce an ActiveModel error on :dialog_before
        expect(instance.errors.any? { |e| e.attribute == :dialog_before }).to be(true),
                                                                              'Expected ActiveModel error on :dialog_before for missing template, but none found'
      end

      it 'has no ActiveModel errors when given valid configuration' do
        # Create a real message template so the validation passes
        Admin::MessageTemplate.create!(
          name: 'test_dialog_template_986',
          message_type: :dialog,
          template_type: :content,
          template: '<p>Test</p>',
          current_admin: @admin
        )
        instance = klass.new(test_field: { name: 'test_dialog_template_986' })
        expect(instance.errors).to be_empty,
                                   "Expected no ActiveModel errors for valid dialog_before, got: #{instance.errors.full_messages}"
      end
    end

    describe 'Embed' do
      let(:klass) { OptionConfigs::ExtraOptionConfigs::Embed }

      it 'produces ActiveModel errors on the instance when resource does not exist' do
        # Simulate what the registry does: call prepare_config then create instance
        yaml = <<~YAML
          default:
            label: Test
            embed: nonexistent_resource_xyz_999
        YAML
        eo = config_for(yaml)

        # Re-create the instance directly to check ActiveModel errors on INSTANCE
        processed = klass.prepare_config('nonexistent_resource_xyz_999', eo)
        instance = klass.new(processed)
        expect(instance.errors.any? { |e| e.attribute == :embed }).to be(true),
                                                                      'Expected ActiveModel error on :embed for non-existent resource, but none found on instance'
      end

      it 'has no ActiveModel errors on the instance when embed is valid' do
        # Use proper plural resource name that Resources::Models recognizes
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

    describe 'References' do
      let(:klass) { OptionConfigs::ExtraOptionConfigs::References }

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
    end

    describe 'FieldConfigs' do
      let(:klass) { OptionConfigs::ExtraOptionConfigs::FieldConfigs }

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
  end

  # ──────────────────────────────────────────────────────────────
  # NfsStoreConfig (issue #986 – migrated from ActivityLogOptions#clean_nfs_store_def)
  # Validates nfs_store keys and delegates pipeline cleaning to NfsStore::Config::ExtraOptions.clean_def
  # ──────────────────────────────────────────────────────────────
  describe 'NfsStoreConfig' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::NfsStoreConfig }

    it 'exists and inherits from BaseConfiguration' do
      expect(klass).to be < OptionConfigs::ExtraOptionConfigs::BaseConfiguration
    end

    it 'stores processed value' do
      expect(klass.store_processed_value?).to be true
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:nfs_store)
    end

    it 'produces ActiveModel errors for invalid top-level nfs_store keys' do
      raw = { always_use_this_for_access_control: true, invalid_key_xyz: 'bad' }
      instance = klass.new(raw)
      expect(instance.errors.any? { |e| e.attribute == :nfs_store }).to be(true),
                                                                        'Expected ActiveModel error on :nfs_store for invalid top-level keys'
    end

    it 'produces ActiveModel errors for invalid can sub-keys' do
      raw = { can: { download_if: true, bogus_permission: 'bad' } }
      instance = klass.new(raw)
      expect(instance.errors.any? { |e| e.attribute == :nfs_store }).to be(true),
                                                                        'Expected ActiveModel error on :nfs_store for invalid can sub-keys'
    end

    it 'has no ActiveModel errors when all keys are valid' do
      raw = { always_use_this_for_access_control: true, can: { download_if: true } }
      instance = klass.new(raw)
      expect(instance.errors).to be_empty,
                                 "Expected no ActiveModel errors for valid nfs_store keys, got: #{instance.errors.full_messages}"
    end

    it 'has no ActiveModel errors when nfs_store is nil' do
      instance = klass.new(nil)
      expect(instance.errors).to be_empty,
                                 "Expected no ActiveModel errors for nil nfs_store, got: #{instance.errors.full_messages}"
    end

    it 'delegates pipeline cleaning via prepare_config' do
      raw = { pipeline: [], user_file_actions: [] }
      expect(NfsStore::Config::ExtraOptions).to receive(:clean_def).with(raw)
      klass.prepare_config(raw, nil)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # ESignConfig (issue #986 – migrated from ActivityLogOptions#clean_e_sign_def)
  # Transforms e_sign document_reference structure: wraps in {item: ...},
  # singularizes keys, and resolves model references.
  # ──────────────────────────────────────────────────────────────
  describe 'ESignConfig' do
    let(:klass) { OptionConfigs::ExtraOptionConfigs::ESignConfig }

    it 'exists and inherits from BaseConfiguration' do
      expect(klass).to be < OptionConfigs::ExtraOptionConfigs::BaseConfiguration
    end

    it 'stores processed value' do
      expect(klass.store_processed_value?).to be true
    end

    it 'declares configure_direct with type :hash' do
      expect(klass.option_types[:direct]).to include(:e_sign)
    end

    it 'wraps document_reference in {item: ...} if not already wrapped' do
      raw = { document_reference: { player_contacts: { label: 'Contact' } } }
      result = klass.prepare_config(raw, nil)
      expect(result[:document_reference]).to have_key(:item),
                                             'Expected document_reference to be wrapped in {item: ...}'
    end

    it 'does not double-wrap document_reference that already has :item key' do
      raw = { document_reference: { item: { player_contacts: { label: 'Contact' } } } }
      result = klass.prepare_config(raw, nil)
      expect(result[:document_reference][:item]).not_to have_key(:item),
                                                        'Expected document_reference not to be double-wrapped'
    end

    it 'singularizes keys within each reference item' do
      raw = { document_reference: { item: { player_contacts: { label: 'Contact' } } } }
      result = klass.prepare_config(raw, nil)
      item = result[:document_reference][:item]
      expect(item).to have_key(:player_contact),
                      'Expected pluralized key :player_contacts to be singularized to :player_contact'
      expect(item).not_to have_key(:player_contacts),
                          'Expected original pluralized key :player_contacts to be removed after singularization'
    end

    it 'resolves model references with to_record_label, no_master_association, to_model_name_us' do
      raw = { document_reference: { item: { player_contacts: { label: 'My Label' } } } }
      result = klass.prepare_config(raw, nil)
      ref = result[:document_reference][:item][:player_contact]
      expect(ref).to have_key(:to_record_label),
                     'Expected :to_record_label to be set on resolved reference'
      expect(ref).to have_key(:to_model_name_us),
                     'Expected :to_model_name_us to be set on resolved reference'
    end

    it 'returns nil from prepare_config when raw is nil' do
      result = klass.prepare_config(nil, nil)
      expect(result).to be_nil
    end
  end

  # ──────────────────────────────────────────────────────────────
  # ActivityLogOptions config_class_registry integration (issue #986)
  # After migration, nfs_store and e_sign should be registered config classes
  # and the old clean_ instance methods should no longer exist.
  # ──────────────────────────────────────────────────────────────
  describe 'ActivityLogOptions config_class_registry' do
    it 'extends parent registry with nfs_store' do
      registry = OptionConfigs::ActivityLogOptions.config_class_registry
      expect(registry).to have_key(:nfs_store),
                          'Expected ActivityLogOptions.config_class_registry to include :nfs_store'
    end

    it 'extends parent registry with e_sign' do
      registry = OptionConfigs::ActivityLogOptions.config_class_registry
      expect(registry).to have_key(:e_sign),
                          'Expected ActivityLogOptions.config_class_registry to include :e_sign'
    end

    it 'maps nfs_store to NfsStoreConfig class' do
      registry = OptionConfigs::ActivityLogOptions.config_class_registry
      expect(registry[:nfs_store]).to eq(OptionConfigs::ExtraOptionConfigs::NfsStoreConfig)
    end

    it 'maps e_sign to ESignConfig class' do
      registry = OptionConfigs::ActivityLogOptions.config_class_registry
      expect(registry[:e_sign]).to eq(OptionConfigs::ExtraOptionConfigs::ESignConfig)
    end

    it 'returns empty add_key_attributes' do
      expect(OptionConfigs::ActivityLogOptions.add_key_attributes).to eq([])
    end

    it 'does not define clean_nfs_store_def as instance method' do
      expect(OptionConfigs::ActivityLogOptions.method_defined?(:clean_nfs_store_def, false)).to be false
    end

    it 'does not define clean_e_sign_def as instance method' do
      expect(OptionConfigs::ActivityLogOptions.method_defined?(:clean_e_sign_def, false)).to be false
    end
  end
end
