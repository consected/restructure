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
