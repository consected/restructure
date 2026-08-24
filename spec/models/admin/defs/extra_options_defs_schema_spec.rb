# frozen_string_literal: true

require 'rails_helper'

# Tests that extra_options_*_defs.yaml schema documentation files follow the
# standardized format agreed in issue #986:
#   1. Canonical schema signature comment
#   2. Named key/value type aliases for dynamic keys and union values
#   3. Pattern examples subordinate to the canonical schema
#   4. Notes section for normalization/semantic constraints
#   5. All keys optional by default; required keys marked (required)
#
# Also verifies that documented attributes in the YAML files match the
# attributes defined in the corresponding Ruby ExtraOptionConfigs classes,
# preventing documentation drift.

RSpec.describe 'Extra options defs YAML schema documentation', type: :model do
  let(:defs_dir) { Rails.root.join('app/models/admin/defs') }

  # Read a defs YAML file and return its raw text content
  def read_defs_file(filename)
    File.read(defs_dir.join(filename))
  end

  # Extract all comment lines from a defs file
  def comment_lines(content)
    content.lines.select { |l| l.strip.start_with?('#') }.map(&:strip)
  end

  # Aggregate defs files (not per-pattern files, not top-level meta files)
  # These are the primary schema documentation files for each config option.
  AGGREGATE_DEFS_FILES = {
    'extra_options_caption_before_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::CaptionBefore',
      schema_key: 'caption_before',
      has_named_config: true,
      pattern_files: [
        { file: 'extra_options_caption_before_pattern_1_simple_defs.yaml', label: 'Pattern 1', content_match: 'caption_before' },
        { file: 'extra_options_caption_before_pattern_2_keep_label_defs.yaml', label: 'Pattern 2', content_match: 'keep_label' },
        { file: 'extra_options_caption_before_pattern_3_view_specific_defs.yaml', label: 'Pattern 3', content_match: 'show_caption' }
      ]
    },
    'extra_options_dialog_before_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::DialogBefore',
      schema_key: 'dialog_before',
      has_named_config: true,
      pattern_files: [
        { file: 'extra_options_dialog_before_pattern_1_simple_defs.yaml', label: 'Pattern 1', content_match: 'dialog_before' },
        { file: 'extra_options_dialog_before_pattern_2_hash_defs.yaml', label: 'Pattern 2', content_match: 'name:' }
      ]
    },
    'extra_options_label_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::Label',
      schema_key: 'label',
      has_named_config: false
    },
    'extra_options_labels_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::Labels',
      schema_key: 'labels',
      has_named_config: false
    },
    'extra_options_field_options_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::FieldOptions',
      schema_key: 'field_options',
      has_named_config: true,
      pattern_files: [
        { file: 'extra_options_field_options_pattern_1_edit_as_defs.yaml', label: 'Pattern 1', content_match: 'alt_options' },
        { file: 'extra_options_field_options_pattern_2_big_select_basic_defs.yaml', label: 'Pattern 2', content_match: 'hide_key' },
        { file: 'extra_options_field_options_pattern_3_big_select_separator_defs.yaml', label: 'Pattern 3', content_match: '>>>' },
        { file: 'extra_options_field_options_pattern_4_big_select_grouped_defs.yaml', label: 'Pattern 4', content_match: 'group_split_char' },
        { file: 'extra_options_field_options_pattern_5_big_select_filtered_defs.yaml', label: 'Pattern 5', content_match: 'filtered' },
        { file: 'extra_options_field_options_pattern_6_creatable_defs.yaml', label: 'Pattern 6', content_match: 'creatable' },
        { file: 'extra_options_field_options_pattern_7_value_lookup_defs.yaml', label: 'Pattern 7', content_match: 'return_value' },
        { file: 'extra_options_field_options_pattern_8_value_array_defs.yaml', label: 'Pattern 8', content_match: 'blood spot card' },
        { file: 'extra_options_field_options_pattern_9_active_value_defs.yaml', label: 'Pattern 9', content_match: 'active_value' }
      ]
    },
    'extra_options_set_variables_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::SetVariable',
      schema_key: 'set_variables',
      has_named_config: false
    },
    'extra_options_preset_fields_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::PresetFields',
      schema_key: 'preset_fields',
      has_named_config: false
    },
    'extra_options_top_level_comments_defs.yaml' => {
      schema_key: '_comments',
      has_named_config: false
    },
    'extra_options_top_level_configurations_defs.yaml' => {
      schema_key: '_configurations',
      has_named_config: false
    },
    'extra_options_top_level_constants_defs.yaml' => {
      schema_key: '_constants',
      has_named_config: false
    },
    'extra_options_top_level_definitions_defs.yaml' => {
      schema_key: '_definitions',
      has_named_config: false
    },
    'extra_options_top_level_override_defs.yaml' => {
      schema_key: '_override',
      has_named_config: false
    },
    'extra_options_top_level_merge_default_defs.yaml' => {
      schema_key: '_merge_default',
      has_named_config: false
    },
    'extra_options_top_level_merge_override_defs.yaml' => {
      schema_key: '_merge_override',
      has_named_config: false
    },
    'extra_options_top_level_db_columns_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::DbColumns',
      schema_key: '_db_columns',
      has_named_config: true
    },
    'extra_options_top_level_data_dictionary_defs.yaml' => {
      schema_key: '_data_dictionary',
      has_named_config: false
    },
    'extra_options_top_level_default_defs.yaml' => {
      schema_key: '_default',
      has_named_config: false
    },
    'extra_options_fields_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::Fields',
      schema_key: 'fields',
      has_named_config: false
    },
    'extra_options_filestore_container_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::Filestore',
      schema_key: 'filestore',
      has_named_config: false
    },
    'extra_options_standard_option_defs.yaml' => {
      schema_key: 'standard_options',
      has_named_config: false
    },
    'extra_options_creatable_if_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::CreatableIf',
      schema_key: 'creatable_if',
      has_named_config: false,
      pattern_files: [
        { file: 'extra_options_creatable_if_pattern_1_always_defs.yaml', label: 'Pattern 1', content_match: 'always' },
        { file: 'extra_options_creatable_if_pattern_2_never_defs.yaml', label: 'Pattern 2', content_match: 'never' },
        { file: 'extra_options_creatable_if_pattern_3_conditional_defs.yaml', label: 'Pattern 3', content_match: 'not_any' }
      ]
    },
    'extra_options_editable_if_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::EditableIf',
      schema_key: 'editable_if',
      has_named_config: false,
      pattern_files: [
        { file: 'extra_options_editable_if_pattern_1_always_defs.yaml', label: 'Pattern 1', content_match: 'always' },
        { file: 'extra_options_editable_if_pattern_2_never_defs.yaml', label: 'Pattern 2', content_match: 'never' },
        { file: 'extra_options_editable_if_pattern_3_conditional_defs.yaml', label: 'Pattern 3', content_match: 'finalized' },
        { file: 'extra_options_editable_if_pattern_4_merge_anchor_defs.yaml', label: 'Pattern 4', content_match: 'some_condition_anchor' }
      ]
    },
    'extra_options_showable_if_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::ShowableIf',
      schema_key: 'showable_if',
      has_named_config: false,
      pattern_files: [
        { file: 'extra_options_showable_if_pattern_1_always_defs.yaml', label: 'Pattern 1', content_match: 'always' },
        { file: 'extra_options_showable_if_pattern_2_never_defs.yaml', label: 'Pattern 2', content_match: 'never' },
        { file: 'extra_options_showable_if_pattern_3_conditional_defs.yaml', label: 'Pattern 3', content_match: 'hidden' }
      ]
    },
    'extra_options_add_reference_if_defs.yaml' => {
      schema_key: 'add_reference_if',
      has_named_config: false,
      pattern_files: [
        { file: 'extra_options_add_reference_if_pattern_1_always_defs.yaml', label: 'Pattern 1', content_match: 'always' },
        { file: 'extra_options_add_reference_if_pattern_2_never_defs.yaml', label: 'Pattern 2', content_match: 'never' },
        { file: 'extra_options_add_reference_if_pattern_3_conditional_defs.yaml', label: 'Pattern 3', content_match: 'not_any' }
      ]
    },
    'extra_options_show_if_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::ShowIf',
      schema_key: 'show_if',
      has_named_config: false,
      pattern_files: [
        { file: 'extra_options_show_if_pattern_1_simple_defs.yaml', label: 'Pattern 1', content_match: 'current_mode' },
        { file: 'extra_options_show_if_pattern_2_combined_defs.yaml', label: 'Pattern 2', content_match: 'not_all' },
        { file: 'extra_options_show_if_pattern_3_embedded_item_defs.yaml', label: 'Pattern 3', content_match: 'embedded_item' },
        { file: 'extra_options_show_if_pattern_4_nested_embedded_defs.yaml', label: 'Pattern 4', content_match: 'embedded_score' },
        { file: 'extra_options_show_if_pattern_5_regex_defs.yaml', label: 'Pattern 5', content_match: 'field_name_regex' },
        { file: 'extra_options_show_if_pattern_6_submit_button_defs.yaml', label: 'Pattern 6', content_match: 'submit_buttons' }
      ]
    },
    'extra_options_references_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::References',
      schema_key: 'references',
      has_named_config: false,
      pattern_files: [
        { file: 'extra_options_references_pattern_1_simple_defs.yaml', label: 'Pattern 1', content_match: 'button label' },
        { file: 'extra_options_references_pattern_2_add_with_filter_defs.yaml', label: 'Pattern 2', content_match: 'add_with' },
        { file: 'extra_options_references_pattern_3_order_type_config_defs.yaml', label: 'Pattern 3', content_match: 'type_config' },
        { file: 'extra_options_references_pattern_4_display_defs.yaml', label: 'Pattern 4', content_match: 'view_as' },
        { file: 'extra_options_references_pattern_5_disable_behavior_defs.yaml', label: 'Pattern 5', content_match: 'prevent_disable' }
      ]
    },
    'extra_options_view_options_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::ViewOptions',
      schema_key: 'view_options',
      has_named_config: false,
      pattern_files: [
        { file: 'extra_options_view_options_pattern_1_basic_defs.yaml', label: 'Pattern 1', content_match: 'data_attribute' },
        { file: 'extra_options_view_options_pattern_2_embedded_reference_defs.yaml', label: 'Pattern 2', content_match: 'show_embedded_at_top' },
        { file: 'extra_options_view_options_pattern_3_alt_order_defs.yaml', label: 'Pattern 3', content_match: 'alt_order' },
        { file: 'extra_options_view_options_pattern_4_sort_references_defs.yaml', label: 'Pattern 4', content_match: 'sort_references' },
        { file: 'extra_options_view_options_pattern_5_form_button_defs.yaml', label: 'Pattern 5', content_match: 'show_cancel' }
      ]
    },
    'extra_options_embed_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::Embed',
      schema_key: 'embed',
      has_named_config: false,
      pattern_files: [
        { file: 'extra_options_embed_pattern_1_default_defs.yaml', label: 'Pattern 1', content_match: 'default_embed_resource' },
        { file: 'extra_options_embed_pattern_2_resource_name_defs.yaml', label: 'Pattern 2', content_match: 'dynamic_model__resource_name' },
        { file: 'extra_options_embed_pattern_3_hash_defs.yaml', label: 'Pattern 3', content_match: 'resource_id' }
      ]
    },
    'extra_options_save_action_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::SaveAction',
      schema_key: 'save_action',
      has_named_config: false
    },
    'extra_options_save_trigger_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::SaveTrigger',
      schema_key: 'save_trigger',
      has_named_config: false
    },
    'extra_options_batch_trigger_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::BatchTrigger',
      schema_key: 'batch_trigger',
      has_named_config: false
    },
    'extra_options_config_trigger_defs.yaml' => {
      config_class: 'OptionConfigs::ExtraOptionConfigs::ConfigTrigger',
      schema_key: 'config_trigger',
      has_named_config: false
    }
  }.freeze

  describe 'schema documentation format' do
    AGGREGATE_DEFS_FILES.each do |filename, meta|
      context filename do
        let(:content) { read_defs_file(filename) }
        let(:comments) { comment_lines(content) }

        it 'has a canonical schema signature comment' do
          # The file must contain a comment line with the canonical schema
          # using the <Type(...)> notation, e.g.:
          #   # caption_before: <Hash(...)>
          # or for scalars:
          #   # label: <String>
          schema_comment = comments.find { |c| c.match?(/^#\s*#{meta[:schema_key]}:\s*</) }
          expect(schema_comment).to be_present,
                                    "#{filename} must contain a canonical schema signature comment " \
                                    "like '# #{meta[:schema_key]}: <Type(...)>'"
        end

        it 'documents value types using the schema notation' do
          # Must contain at least one type reference using angle brackets
          type_comments = comments.select { |c| c.match?(/<\w+/) }
          expect(type_comments).not_to be_empty,
                                       "#{filename} must document value types using <Type> notation"
        end

        it 'has a Notes section' do
          notes_comment = comments.find { |c| c.match?(/^#\s*Notes:/) }
          expect(notes_comment).to be_present,
                                   "#{filename} must contain a '# Notes:' section for normalization/semantic constraints"
        end
      end
    end
  end

  describe 'documented attributes match Ruby config class' do
    AGGREGATE_DEFS_FILES.each do |filename, meta|
      next unless meta[:has_named_config]

      context filename do
        let(:content) { read_defs_file(filename) }
        let(:config_class) { meta[:config_class].constantize }
        let(:named_config_class) { config_class.const_get(:NamedConfiguration) }

        it 'documents all NamedConfiguration attributes' do
          # Get the attributes defined in the Ruby NamedConfiguration class
          ruby_attrs = named_config_class.option_types[:simple] || []
          expect(ruby_attrs).not_to be_empty,
                                    "#{config_class}::NamedConfiguration should have configure_attributes"

          # Each Ruby attribute should be mentioned in the YAML file
          ruby_attrs.each do |attr|
            expect(content).to include(attr.to_s),
                               "#{filename} must document the '#{attr}' attribute " \
                               "from #{config_class}::NamedConfiguration"
          end
        end

        it 'does not use ? suffix for optional keys' do
          # Per agreed convention: keys are optional by default, not marked with ?
          optional_key_pattern = /^\s*#.*\w+\?:\s/
          lines_with_optional = content.lines.select { |l| l.match?(optional_key_pattern) }
          expect(lines_with_optional).to be_empty,
                                         "#{filename} should not use '?' suffix for optional keys. " \
                                         'Keys are optional by default; mark required keys with (required) instead.'
        end
      end
    end
  end

  describe 'dynamic key documentation' do
    context 'caption_before' do
      let(:content) { read_defs_file('extra_options_caption_before_defs.yaml') }

      it 'documents the caption_target_key type with all allowed forms' do
        # Must document: valid_field_name, all_fields, submit, reference_<reference_name>
        expect(content).to match(/all_fields/),
                           'caption_before must document the all_fields pseudo-key'
        expect(content).to match(/submit/),
                           'caption_before must document the submit pseudo-key'
        expect(content).to match(/reference_/),
                           'caption_before must document the reference_<reference_name> key pattern'
      end

      it 'documents the key type as a named alias' do
        comments = comment_lines(content)
        # Should have a named key type definition, e.g.:
        #   # caption_target_key: <valid_field_name | all_fields | submit | reference_<reference_name>>
        key_type_comment = comments.find { |c| c.match?(/caption_target_key/) }
        expect(key_type_comment).to be_present,
                                    'caption_before must define a named key type (caption_target_key) for its dynamic keys'
      end
    end

    context 'dialog_before' do
      let(:content) { read_defs_file('extra_options_dialog_before_defs.yaml') }

      it 'documents the dialog_target_key type with all allowed forms' do
        expect(content).to match(/all_fields/),
                           'dialog_before must document the all_fields pseudo-key'
        expect(content).to match(/submit/),
                           'dialog_before must document the submit pseudo-key'
      end

      it 'marks name as required in the value type' do
        expect(content).to match(/name.*\(required\)/i),
                           'dialog_before must mark name as (required) in the value type documentation'
      end
    end
  end

  describe 'pattern examples in per-pattern files' do
    AGGREGATE_DEFS_FILES.each do |filename, meta|
      next unless meta[:pattern_files]

      context meta[:schema_key] do
        meta[:pattern_files].each do |pattern|
          it "has a #{pattern[:label]} per-pattern file (#{pattern[:file]})" do
            content = read_defs_file(pattern[:file])
            expect(content).to match(/#{Regexp.escape(pattern[:label])}/)
            expect(content).to match(/#{Regexp.escape(pattern[:content_match])}/)
          end
        end

        it 'aggregate file references the per-pattern files' do
          content = read_defs_file(filename)
          meta[:pattern_files].each do |pattern|
            expect(content).to include(pattern[:file])
          end
        end
      end
    end
  end
end
