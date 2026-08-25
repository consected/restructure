# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Integration tests for ExtraOptions initialization sequence.
# Verifies config_instances, attribute storage, old clean_ method removal,
# resource_name initialization, config_obj mutation, and full end-to-end
# initialization with multiple config areas.
RSpec.describe 'ExtraOptions integration', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include ExtraOptionConfigsSupport

  before(:all) do
    set_up_extra_options_configs
  end

  # ──────────────────────────────────────────────────────────────
  # config_instances
  # ──────────────────────────────────────────────────────────────
  describe 'config_instances' do
    it 'stores config_instances after initialization (empty since all converted to BaseConfiguration)' do
      eo = config_for(<<~YAML)
        default:
          label: Integration Test
          fields:
            - test1
      YAML

      expect(eo).to respond_to(:config_instances)
      expect(eo.config_instances).to be_a Hash
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

      ExtraOptionConfigsSupport::FIELD_KEYED_CLASSES.each do |class_name|
        key = class_name.to_s.underscore.to_sym
        expect(eo.config_instances).not_to have_key(key),
                                           "#{class_name} should not be in config_instances (stored directly as attribute)"
      end

      ExtraOptionConfigsSupport::TYPED_CONFIG_CLASSES.each do |class_name|
        key = ExtraOptionConfigsSupport::EXPECTED_CONFIG_CLASSES.key(class_name)
        expect(eo.config_instances).not_to have_key(key),
                                           "#{class_name} should not be in config_instances (stored directly as attribute)"
      end
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Attribute storage patterns
  # ──────────────────────────────────────────────────────────────
  describe 'attribute storage patterns' do
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

      expect(eo.label).to eq 'Matching Test'
      expect(eo.fields).to eq %w[test1 test2]
      expect(eo.labels[:test1]).to eq 'Test One'
      expect(eo.view_options).to be_a OptionConfigs::ExtraOptionConfigs::ViewOptions
      expect(eo.view_options[:data_attribute]).to eq 'test1'
      expect(eo.preset_fields[:test1]).to eq 'preset_val'
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
  end

  # ──────────────────────────────────────────────────────────────
  # config_obj mutation
  # ──────────────────────────────────────────────────────────────
  describe 'config_obj mutation handling' do
    it 'sets config_obj.db_columns from db_configs after DbConfigs runs' do
      eo = config_for(<<~YAML)
        default:
          db_configs:
            some_column: some_value
      YAML

      expect(@dm.db_columns).to eq(some_column: 'some_value')
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Old clean_ methods removed
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
  # resource_name initialization
  # ──────────────────────────────────────────────────────────────
  describe 'resource_name initialization' do
    it 'sets resource_name from config_obj and option name' do
      eo = config_for(<<~YAML)
        my_option:
          label: Test
      YAML

      expect(eo.resource_name).to include('my_option')
      expect(eo.resource_item_name).to eq eo.resource_name
    end
  end

  # ──────────────────────────────────────────────────────────────
  # Full initialization sequence
  # ──────────────────────────────────────────────────────────────
  describe 'full initialization with multiple configs' do
    it 'initializes all clean_ methods in sequence without errors for valid config' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
            - test2
          label: Full Test
          labels:
            test1: Test One
            test2: Test Two
          caption_before:
            test1: Caption One
          view_options:
            data_attribute: test1
          save_action:
            on_save:
              label: Saved
          field_options:
            test1:
              no_downcase: true
          preset_fields:
            test1: preset_val
      YAML

      expect(eo.config_errors).to be_empty
      expect(eo.label).to eq 'Full Test'
      expect(eo.fields).to eq %w[test1 test2]
      expect(eo.labels.symbolize_keys).to eq(test1: 'Test One', test2: 'Test Two')
      expect(eo.caption_before[:test1]).to respond_to(:[])
      expect(eo.caption_before[:test1][:caption]).to be_present
      expect(eo.view_options[:data_attribute]).to eq 'test1'
      expect(eo.save_action[:on_create][:label]).to eq 'Saved'
      expect(eo.field_options[:test1][:no_downcase]).to eq true
      expect(eo.preset_fields[:test1]).to eq 'preset_val'
    end

    it 'handles multiple named option configs from a single definition' do
      configs = all_configs_for(<<~YAML)
        option_a:
          label: Option A
          fields:
            - test1
        option_b:
          label: Option B
          fields:
            - test2
      YAML

      names = configs.map(&:name)
      expect(names).to include(:option_a)
      expect(names).to include(:option_b)
      expect(configs.length).to be >= 2
    end
  end
end
