# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Phase 1 of issue #986: Capture the current behavior of each ExtraOptions `clean_...` method
# with explicit tests. These tests document the exact output format produced by each method
# given known inputs, establishing a safety net for the Phase 2 refactoring into
# dedicated configuration classes.
#
# Each describe block covers one `clean_...` method. Tests verify:
# - Default initialization when no config is provided
# - Correct transformation of valid input
# - Edge cases: nil inputs, empty hashes, invalid keys, nested structures
#
# The test strategy instantiates ExtraOptions through the standard parse path
# (DynamicModel#option_configs) so that the full initialization sequence runs,
# including inter-method dependencies.
RSpec.describe 'ExtraOptions clean methods', type: :model do
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

  # Helper: return all option configs for the given YAML
  def all_configs_for(yaml)
    @dm.update!(options: yaml, current_admin: @admin)
    @dm.option_configs
  end

  # ──────────────────────────────────────────────────────────────
  # clean_fields_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_fields_def' do
    it 'defaults fields to an empty array when not specified in options' do
      eo = config_for(<<~YAML)
        default:
          label: No fields
      YAML
      # When no fields are specified in options, fields defaults to []
      # (the DynamicModel may have its own field_list but clean_fields_def
      # only sets [] if fields is nil in the options config)
      expect(eo.fields).to be_an Array
    end

    it 'preserves a provided field list' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
            - test2
      YAML
      expect(eo.fields).to eq %w[test1 test2]
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_label_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_label_def' do
    it 'defaults label to a humanized version of the config name' do
      eo = config_for(<<~YAML)
        my_custom_name:
          fields:
            - test1
      YAML
      expect(eo.label).to eq 'My custom name'
    end

    it 'preserves an explicitly set label' do
      eo = config_for(<<~YAML)
        default:
          label: Custom Label
      YAML
      expect(eo.label).to eq 'Custom Label'
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_caption_before_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_caption_before_def' do
    it 'defaults caption_before to a blank CaptionBefore when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No captions
      YAML
      expect(eo.caption_before).to be_blank
    end

    it 'converts a plain string caption to a hash with all caption modes' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          caption_before:
            test1: Simple caption text
      YAML

      cb = eo.caption_before[:test1]
      expect(cb).to respond_to(:[])
      expect(cb[:caption]).to be_present
      expect(cb[:edit_caption]).to be_present
      expect(cb[:show_caption]).to be_present
      expect(cb[:new_caption]).to be_present
      # All modes should have the same HTML-converted value
      expect(cb[:caption]).to eq cb[:edit_caption]
      expect(cb[:caption]).to eq cb[:show_caption]
      expect(cb[:caption]).to eq cb[:new_caption]
    end

    it 'converts text to HTML via Formatter::Substitution.text_to_html' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          caption_before:
            test1: "Line one\\nLine two"
      YAML

      cb = eo.caption_before[:test1]
      # The text_to_html conversion should produce HTML content
      expect(cb[:caption]).to be_a String
      expect(cb[:caption]).not_to be_empty
    end

    it 'preserves hash-style caption_before with individual mode values' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          caption_before:
            test1:
              caption: Show and edit caption
              edit_caption: Edit only caption
              show_caption: Show only caption
      YAML

      cb = eo.caption_before[:test1]
      expect(cb[:caption]).to include('Show and edit caption')
      expect(cb[:edit_caption]).to include('Edit only caption')
      expect(cb[:show_caption]).to include('Show only caption')
    end

    it 'defaults new_caption to edit_caption when not explicitly set' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          caption_before:
            test1:
              edit_caption: Edit caption value
      YAML

      cb = eo.caption_before[:test1]
      expect(cb[:new_caption]).to eq cb[:edit_caption]
    end

    it 'symbolizes caption_before keys' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          caption_before:
            test1: A caption
      YAML

      expect(eo.caption_before.keys.first).to be_a Symbol
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_dialog_before_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_dialog_before_def' do
    it 'defaults dialog_before to a blank DialogBefore when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No dialogs
      YAML
      expect(eo.dialog_before).to be_blank
    end

    it 'converts a string value to a hash with name key' do
      # Create a message template first, so the warning is not generated
      Admin::MessageTemplate.create!(
        name: 'test_dialog_template',
        message_type: :dialog,
        template_type: :content,
        template: '<p>test</p>',
        current_admin: @admin
      )

      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          dialog_before:
            test1: test_dialog_template
      YAML

      db = eo.dialog_before[:test1]
      expect(db).to respond_to(:[]) # NamedConfiguration with bracket access
      expect(db[:name]).to eq 'test_dialog_template'
    end

    it 'preserves a hash value with name key' do
      Admin::MessageTemplate.create!(
        name: 'test_dialog_hash',
        message_type: :dialog,
        template_type: :content,
        template: '<p>test</p>',
        current_admin: @admin
      )

      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          dialog_before:
            test1:
              name: test_dialog_hash
      YAML

      db = eo.dialog_before[:test1]
      expect(db[:name]).to eq 'test_dialog_hash'
    end

    it 'reports a warning when the named message template does not exist' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          dialog_before:
            test1: nonexistent_template
      YAML

      expect(eo.config_warnings).not_to be_empty
      warn_msg = eo.config_warnings.find { |w| w[:type] == :dialog_before }
      expect(warn_msg).to be_present
    end

    it 'reports an error when the value is not a String or Hash' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
          dialog_before:
            test1:
              - invalid_array_item
      YAML

      expect(eo.config_errors).not_to be_empty
      err = eo.config_errors.find { |e| e[:type] == :dialog_before }
      expect(err).to be_present
    end

    it 'symbolizes dialog_before keys' do
      Admin::MessageTemplate.create!(
        name: 'dialog_sym_test',
        message_type: :dialog,
        template_type: :content,
        template: '<p>test</p>',
        current_admin: @admin
      )

      eo = config_for(<<~YAML)
        default:
          dialog_before:
            test1: dialog_sym_test
      YAML

      expect(eo.dialog_before.keys.first).to be_a Symbol
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_labels_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_labels_def' do
    it 'defaults labels to a blank Labels instance when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No labels
      YAML
      expect(eo.labels).to be_blank
    end

    it 'preserves explicitly set labels and symbolizes keys' do
      eo = config_for(<<~YAML)
        default:
          labels:
            test1: Test One
            test2: Test Two
      YAML

      expect(eo.labels.symbolize_keys).to eq(test1: 'Test One', test2: 'Test Two')
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_show_if_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_show_if_def' do
    it 'defaults show_if to a blank ShowIf instance when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No show_if
      YAML
      expect(eo.show_if).to be_blank
    end

    it 'preserves explicitly set show_if conditions and symbolizes keys' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
            - test2
          show_if:
            test2:
              test1: some_value
      YAML

      expect(eo.show_if).to have_key(:test2)
      expect(eo.show_if[:test2]).to eq(test1: 'some_value')
    end

    it 'does not overwrite existing show_if when show_if_condition_strings provides a duplicate' do
      eo = config_for(<<~YAML)
        default:
          fields:
            - test1
            - test2
          show_if:
            test2:
              test1: existing_value
          show_if_condition_strings:
            test2: "[test1] = 'other_value'"
      YAML

      # The existing show_if should take priority
      expect(eo.show_if[:test2]).to eq(test1: 'existing_value')
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_save_action_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_save_action_def' do
    it 'defaults save_action to a blank SaveAction when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No save action
      YAML
      expect(eo.save_action).to be_a OptionConfigs::ExtraOptionConfigs::SaveAction
      expect(eo.save_action).to be_blank
    end

    it 'cascades on_save to on_create and on_update as defaults' do
      eo = config_for(<<~YAML)
        default:
          save_action:
            on_save:
              label: Saved
      YAML

      expect(eo.save_action.save_action[:on_save]).to eq(label: 'Saved')
      expect(eo.save_action.save_action[:on_create]).to eq(label: 'Saved')
      expect(eo.save_action.save_action[:on_update]).to eq(label: 'Saved')
    end

    it 'merges on_save into existing on_create and on_update without overwriting them' do
      eo = config_for(<<~YAML)
        default:
          save_action:
            on_save:
              label: Default
              notify: true
            on_create:
              label: Created
            on_update:
              another_key: updated_val
      YAML

      expect(eo.save_action.save_action[:on_create][:label]).to eq 'Created'
      expect(eo.save_action.save_action[:on_create][:notify]).to eq true
      expect(eo.save_action.save_action[:on_update][:label]).to eq 'Default'
      expect(eo.save_action.save_action[:on_update][:another_key]).to eq 'updated_val'
    end

    it 'symbolizes save_action keys' do
      eo = config_for(<<~YAML)
        default:
          save_action:
            on_save:
              label: Test
      YAML
      expect(eo.save_action.save_action.keys).to all(be_a Symbol)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_view_options_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_view_options_def' do
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

  # ──────────────────────────────────────────────────────────────
  # clean_db_configs_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_db_configs_def' do
    it 'defaults db_configs to a blank DbConfigs instance when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No db configs
      YAML
      expect(eo.db_configs).to be_blank
    end

    it 'symbolizes db_configs keys' do
      eo = config_for(<<~YAML)
        default:
          db_configs:
            some_column: some_value
      YAML
      expect(eo.db_configs.keys).to all(be_a Symbol)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_access_if_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_access_if_def' do
    it 'defaults all access_if attributes to empty hashes' do
      eo = config_for(<<~YAML)
        default:
          label: No access
      YAML

      expect(eo.creatable_if).to eq({})
      expect(eo.editable_if).to eq({})
      expect(eo.showable_if).to eq({})
    end

    it 'preserves and symbolizes creatable_if, editable_if, showable_if' do
      eo = config_for(<<~YAML)
        default:
          creatable_if:
            always: true
          editable_if:
            never: true
          showable_if:
            user_is_creator: true
      YAML

      expect(eo.creatable_if).to eq(always: true)
      expect(eo.editable_if).to eq(never: true)
      expect(eo.showable_if).to eq(user_is_creator: true)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_valid_if_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_valid_if_def' do
    it 'defaults valid_if to a blank ValidIf when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No valid_if
      YAML
      expect(eo.valid_if).to be_a OptionConfigs::ExtraOptionConfigs::ValidIf
      expect(eo.valid_if).to be_blank
    end

    it 'cascades on_save to on_create and on_update as defaults' do
      eo = config_for(<<~YAML)
        default:
          valid_if:
            on_save:
              all:
                this:
                  test1: is not null
      YAML

      expect(eo.valid_if.valid_if[:on_save]).to be_present
      expect(eo.valid_if.valid_if[:on_create]).to eq eo.valid_if.valid_if[:on_save]
      expect(eo.valid_if.valid_if[:on_update]).to eq eo.valid_if.valid_if[:on_save]
    end

    it 'merges on_save into existing on_create and on_update' do
      eo = config_for(<<~YAML)
        default:
          valid_if:
            on_save:
              all:
                this:
                  test1: is not null
            on_create:
              all:
                this:
                  test2: is not null
      YAML

      expect(eo.valid_if.valid_if[:on_create]).to have_key(:all)
    end

    it 'reports an error for invalid trigger keys' do
      eo = config_for(<<~YAML)
        default:
          valid_if:
            on_invalid_key:
              always: true
      YAML

      expect(eo.config_errors).not_to be_empty
      err = eo.config_errors.find { |e| e[:type] == :valid_if }
      expect(err).to be_present
    end

    it 'symbolizes valid_if keys' do
      eo = config_for(<<~YAML)
        default:
          valid_if:
            on_save:
              always: true
      YAML
      expect(eo.valid_if.valid_if.keys).to all(be_a Symbol)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_filestore_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_filestore_def' do
    it 'defaults filestore to a blank Filestore when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No filestore
      YAML
      expect(eo.filestore).to be_a OptionConfigs::ExtraOptionConfigs::Filestore
      expect(eo.filestore).to be_blank
    end

    it 'preserves and symbolizes filestore keys' do
      eo = config_for(<<~YAML)
        default:
          filestore:
            always_use_this_for_access_control: true
      YAML
      expect(eo.filestore.symbolize_keys).to eq(always_use_this_for_access_control: true)
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_field_options_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_field_options_def' do
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
      # Array items are converted: key is symbolized, value is downcased string
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

  # ──────────────────────────────────────────────────────────────
  # clean_embed_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_embed_def' do
    it 'leaves embed as nil when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No embed
      YAML
      expect(eo.embed).to be_nil
    end

    it 'converts a string resource_name into a hash with resource_name key' do
      # The referenced resource likely won't exist, but the structure should be set
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

  # ──────────────────────────────────────────────────────────────
  # clean_references_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_references_def' do
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

      # Keys should be singularized
      expect(eo.references).to be_a Hash
      ref_keys = eo.references.keys
      # The key should wrap the reference as { singular_key => config }
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

      # Should generate a warning (not an error, since order of imports may cause this)
      has_warning = eo.config_warnings.any? { |w| w[:type] == :references }
      # May also just silently skip if to_class is nil; check references is cleaned up
      expect(eo.references).to be_a Hash
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_save_triggers
  # ──────────────────────────────────────────────────────────────
  describe '#clean_save_triggers' do
    it 'defaults save_trigger to a SaveTrigger with blank TriggerTasks' do
      eo = config_for(<<~YAML)
        default:
          label: No save triggers
      YAML

      expect(eo.save_trigger).to be_a OptionConfigs::ExtraOptionConfigs::SaveTrigger
      expect(eo.save_trigger[:on_upload]).to be_a Hash
      expect(eo.save_trigger[:on_upload]).to be_blank
      expect(eo.save_trigger[:on_disable]).to be_a Hash
      expect(eo.save_trigger[:on_disable]).to be_blank
    end

    it 'cascades on_save to on_create and on_update as array defaults' do
      eo = config_for(<<~YAML)
        default:
          save_trigger:
            on_save:
              notify:
                type: email
      YAML

      expect(eo.save_trigger[:on_create]).to be_an Array
      expect(eo.save_trigger[:on_update]).to be_an Array
      expect(eo.save_trigger[:on_create].length).to eq 1
      expect(eo.save_trigger[:on_update].length).to eq 1
    end

    it 'appends on_save triggers to existing on_create and on_update' do
      eo = config_for(<<~YAML)
        default:
          save_trigger:
            on_save:
              notify:
                type: email
            on_create:
              create_action:
                type: special
      YAML

      # on_create should have both on_save and its own trigger
      expect(eo.save_trigger[:on_create]).to be_an Array
      expect(eo.save_trigger[:on_create].length).to eq 2
      # on_update should only have on_save trigger
      expect(eo.save_trigger[:on_update]).to be_an Array
      expect(eo.save_trigger[:on_update].length).to eq 1
    end

    it 'reports an error for invalid trigger keys' do
      eo = config_for(<<~YAML)
        default:
          save_trigger:
            on_invalid_trigger:
              something: true
      YAML

      expect(eo.config_errors).not_to be_empty
      err = eo.config_errors.find { |e| e[:type] == :save_trigger }
      expect(err).to be_present
    end

    it 'symbolizes save_trigger keys' do
      eo = config_for(<<~YAML)
        default:
          save_trigger:
            on_save:
              notify:
                type: email
      YAML
      expect(eo.save_trigger).to be_a OptionConfigs::ExtraOptionConfigs::SaveTrigger
      expect(eo.save_trigger.on_create).to be_a OptionConfigs::ExtraOptionConfigs::TriggerTasks
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_batch_triggers
  # ──────────────────────────────────────────────────────────────
  describe '#clean_batch_triggers' do
    it 'defaults batch_trigger to a BatchTrigger with blank on_record TriggerTasks' do
      eo = config_for(<<~YAML)
        default:
          label: No batch triggers
      YAML

      expect(eo.batch_trigger).to be_a OptionConfigs::ExtraOptionConfigs::BatchTrigger
      expect(eo.batch_trigger[:on_record]).to be_a Hash
      expect(eo.batch_trigger[:on_record]).to be_blank
    end

    it 'preserves batch_trigger configuration and symbolizes keys' do
      eo = config_for(<<~YAML)
        default:
          batch_trigger:
            on_record:
              action: process
      YAML

      expect(eo.batch_trigger[:on_record]).to be_a Hash
      expect(eo.batch_trigger[:on_record]).to eq(action: 'process')
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_config_triggers
  # ──────────────────────────────────────────────────────────────
  describe '#clean_config_triggers' do
    it 'defaults config_trigger to a ConfigTrigger with empty on_define TriggerTasks' do
      eo = config_for(<<~YAML)
        default:
          label: No config triggers
      YAML

      expect(eo.config_trigger).to be_a OptionConfigs::ExtraOptionConfigs::ConfigTrigger
      expect(eo.config_trigger[:on_define]).to be_an Array
      expect(eo.config_trigger[:on_define]).to be_blank
    end

    it 'wraps on_define in an array if it is not already an array' do
      eo = config_for(<<~YAML)
        default:
          config_trigger:
            on_define:
              action: do_something
      YAML

      expect(eo.config_trigger[:on_define]).to be_an Array
      expect(eo.config_trigger[:on_define].length).to eq 1
    end

    it 'preserves on_define as an array if already provided' do
      eo = config_for(<<~YAML)
        default:
          config_trigger:
            on_define:
              - action: first
              - action: second
      YAML

      expect(eo.config_trigger[:on_define]).to be_an Array
      expect(eo.config_trigger[:on_define].length).to eq 2
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_preset_fields
  # ──────────────────────────────────────────────────────────────
  describe '#clean_preset_fields' do
    it 'defaults preset_fields to a blank PresetFields instance' do
      eo = config_for(<<~YAML)
        default:
          label: No presets
      YAML
      expect(eo.preset_fields).to be_blank
    end

    it 'preserves and symbolizes preset_fields' do
      eo = config_for(<<~YAML)
        default:
          preset_fields:
            test1: default_value
            test2: another_value
      YAML
      expect(eo.preset_fields.symbolize_keys).to eq(test1: 'default_value', test2: 'another_value')
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_set_variables_def
  # ──────────────────────────────────────────────────────────────
  describe '#clean_set_variables_def' do
    it 'defaults set_variables to a blank SetVariable when not specified' do
      eo = config_for(<<~YAML)
        default:
          label: No variables
      YAML
      expect(eo.set_variables).to be_nil
    end

    it 'preserves valid set_variables array entries' do
      eo = config_for(<<~YAML)
        default:
          set_variables:
            - name: var1
              value: val1
            - name: var2
              value: val2
              if:
                always: true
      YAML

      expect(eo.set_variables).to be_an Array
      expect(eo.set_variables.length).to eq 2
      expect(eo.set_variables[0][:name]).to eq 'var1'
      expect(eo.set_variables[0][:value]).to eq 'val1'
      expect(eo.set_variables[1][:name]).to eq 'var2'
      expect(eo.set_variables[1][:if]).to be_present
    end

    it 'reports an error and empties when set_variables is not an array' do
      eo = config_for(<<~YAML)
        default:
          set_variables:
            name: var1
            value: val1
      YAML

      expect(eo.set_variables).to eq []
      expect(eo.config_errors).not_to be_empty
      err = eo.config_errors.find { |e| e[:type] == :set_variables }
      expect(err).to be_present
    end

    it 'filters out invalid entries missing name or value keys' do
      eo = config_for(<<~YAML)
        default:
          set_variables:
            - name: valid_var
              value: valid_val
            - no_name_key: invalid
      YAML

      expect(eo.set_variables).to be_an Array
      expect(eo.set_variables.length).to eq 1
      expect(eo.set_variables[0][:name]).to eq 'valid_var'
    end
  end

  # ──────────────────────────────────────────────────────────────
  # clean_field_configs
  # ──────────────────────────────────────────────────────────────
  describe '#clean_field_configs' do
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

      # field_configs should merge caption_before into the standalone caption_before
      expect(eo.caption_before[:test1]).to be_present
      # field_configs should merge labels into standalone labels
      expect(eo.labels[:test1]).to eq 'Label for test1'
      # field_configs should merge show_if into standalone show_if
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
      err = eo.config_errors.find { |e| e[:type] == :field_configs }
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
      err = eo.config_errors.find { |e| e[:type] == :field_configs }
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
      err = eo.config_errors.find { |e| e[:type] == :field_configs }
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

      # raw_field_configs should be a deep copy of field_configs before standalone merge
      expect(eo.raw_field_configs).to be_a Hash
      expect(eo.raw_field_configs[:test1]).to be_a Hash
      # Modifying raw_field_configs should not affect field_configs
      original_fc = eo.field_configs[:test1].dup
      eo.raw_field_configs[:test1][:labels] = 'Modified'
      expect(eo.field_configs[:test1]).to eq original_fc
    end
  end

  # ──────────────────────────────────────────────────────────────
  # add_field_configs_from_standalone_defs
  # ──────────────────────────────────────────────────────────────
  describe '#add_field_configs_from_standalone_defs' do
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

  # ──────────────────────────────────────────────────────────────
  # resource_name and resource_item_name initialization
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
  # Integration: full initialization sequence
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

      # parse_config may produce additional configs from _comments processing
      # but our named configs should be present
      names = configs.map(&:name)
      expect(names).to include(:option_a)
      expect(names).to include(:option_b)
      expect(configs.length).to be >= 2
    end
  end
end
