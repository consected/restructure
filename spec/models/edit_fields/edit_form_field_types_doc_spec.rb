# frozen_string_literal: true

# Spec to verify that the field types documentation (docs/admin_reference/general/field_types.md)
# is complete and accurate. Issue #1071.
#
# This spec dynamically scans the edit field templates in
# app/views/common_templates/edit_fields/ and verifies that each one is
# documented in the field_types.md reference file. It also checks that
# the documentation covers the matching priority order, the
# edit_as.field_type override mechanism, and key field_options attributes
# that affect rendering.
#
# The spec is intentionally written to fail when new templates are added
# but not yet documented, serving as a living documentation check.

require 'rails_helper'

RSpec.describe 'Edit field types documentation', type: :model do
  let(:doc_path) { Rails.root.join('docs', 'admin_reference', 'general', 'field_types.md') }
  let(:template_dir) { Rails.root.join('app', 'views', 'common_templates', 'edit_fields') }

  # Dynamically discover all template names from the edit_fields directory
  let(:all_template_files) do
    Dir.entries(template_dir)
       .reject { |fn| fn.start_with?('.') }
       .map { |fn| fn.sub(/\A_/, '').sub(/\.html\.erb\z/, '') }
       .sort
  end

  # Sub-templates that are rendered by other templates, not matched directly
  let(:sub_templates) { %w[button_radio creatable_select_input] }

  # Templates matched directly by the field matching logic
  let(:matched_templates) { all_template_files - sub_templates }

  # Template categories based on naming convention
  let(:redcap_templates) { matched_templates.select { |t| t.start_with?('redcap_') } }
  let(:name_is_templates) { matched_templates.select { |t| t.start_with?('name_is_') } }
  let(:name_starts_with_templates) { matched_templates.select { |t| t.start_with?('name_starts_with_') } }
  let(:name_ends_with_templates) { matched_templates.select { |t| t.start_with?('name_ends_with_') } }
  let(:column_type_templates) { matched_templates.select { |t| t.start_with?('column_type_') } }
  let(:special_templates) { %w[default is_general_selection is_external_id respond_to_options] }

  describe 'documentation file' do
    it 'exists at docs/admin_reference/general/field_types.md' do
      expect(File.exist?(doc_path)).to eq(true),
                                       "Expected documentation file at #{doc_path} but it does not exist"
    end
  end

  context 'when the documentation file exists', if: File.exist?(Rails.root.join('docs', 'admin_reference', 'general', 'field_types.md')) do
    let(:doc_content) { File.read(doc_path) }

    describe 'template coverage' do
      it 'documents every edit field template' do
        undocumented = []
        all_template_files.each do |template_name|
          undocumented << template_name unless doc_content.include?(template_name)
        end

        expect(undocumented).to be_empty,
                                "The following templates are not documented in field_types.md:\n  #{undocumented.join("\n  ")}"
      end

      it 'documents all REDCap field templates' do
        undocumented = redcap_templates.reject { |t| doc_content.include?(t) }
        expect(undocumented).to be_empty,
                                "Undocumented REDCap templates:\n  #{undocumented.join("\n  ")}"
      end

      it 'documents all name_is field templates' do
        undocumented = name_is_templates.reject { |t| doc_content.include?(t) }
        expect(undocumented).to be_empty,
                                "Undocumented name_is templates:\n  #{undocumented.join("\n  ")}"
      end

      it 'documents all name_starts_with field templates' do
        undocumented = name_starts_with_templates.reject { |t| doc_content.include?(t) }
        expect(undocumented).to be_empty,
                                "Undocumented name_starts_with templates:\n  #{undocumented.join("\n  ")}"
      end

      it 'documents all name_ends_with field templates' do
        undocumented = name_ends_with_templates.reject { |t| doc_content.include?(t) }
        expect(undocumented).to be_empty,
                                "Undocumented name_ends_with templates:\n  #{undocumented.join("\n  ")}"
      end

      it 'documents all column_type field templates' do
        undocumented = column_type_templates.reject { |t| doc_content.include?(t) }
        expect(undocumented).to be_empty,
                                "Undocumented column_type templates:\n  #{undocumented.join("\n  ")}"
      end

      it 'documents all special field templates' do
        undocumented = special_templates.reject { |t| doc_content.include?(t) }
        expect(undocumented).to be_empty,
                                "Undocumented special templates:\n  #{undocumented.join("\n  ")}"
      end

      it 'documents all sub-templates' do
        undocumented = sub_templates.reject { |t| doc_content.include?(t) }
        expect(undocumented).to be_empty,
                                "Undocumented sub-templates:\n  #{undocumented.join("\n  ")}"
      end
    end

    describe 'matching priority order' do
      it 'documents the matching priority order' do
        expect(doc_content).to match(/priority|matching order/i),
                               'Documentation should describe the matching priority order'
      end

      it 'documents REDCap prefix matching as the first priority' do
        expect(doc_content).to match(/redcap.*(first|1\.|highest|prefix)/im),
                               'Documentation should describe REDCap prefix matching as the first priority'
      end

      it 'documents name-exact matching' do
        expect(doc_content).to match(/name.is.*exact|exact.*name.*match/im),
                               'Documentation should describe name-exact (name_is_) matching'
      end

      it 'documents name-prefix matching' do
        expect(doc_content).to match(/name.starts.with.*prefix|prefix.*name.*match/im),
                               'Documentation should describe name-prefix (name_starts_with_) matching'
      end

      it 'documents name-suffix matching' do
        expect(doc_content).to match(/name.ends.with.*suffix|suffix.*name.*match/im),
                               'Documentation should describe name-suffix (name_ends_with_) matching'
      end

      it 'documents that longer prefixes and suffixes match first' do
        expect(doc_content).to match(/long(er|est).*match|specific.*first|length/im),
                               'Documentation should note that longer prefix/suffix patterns take precedence'
      end

      it 'documents respond_to_options matching' do
        expect(doc_content).to match(/respond.to.options/i),
                               'Documentation should describe respond_to_options matching'
      end

      it 'documents GeneralSelection matching' do
        expect(doc_content).to match(/general.selection/i),
                               'Documentation should describe GeneralSelection matching'
      end

      it 'documents external identifier matching' do
        expect(doc_content).to match(/external.id|external.identifier/i),
                               'Documentation should describe external identifier matching'
      end

      it 'documents column type matching' do
        expect(doc_content).to match(/column.type/i),
                               'Documentation should describe column type matching'
      end

      it 'documents default fallback' do
        expect(doc_content).to match(/default|fallback|text.input/i),
                               'Documentation should describe the default fallback to text input'
      end
    end

    describe 'edit_as.field_type override mechanism' do
      it 'documents the edit_as.field_type override' do
        expect(doc_content).to match(/edit_as.*field_type|field_type.*override/im),
                               'Documentation should describe the edit_as.field_type override mechanism'
      end

      it 'explains how field_type overrides the field name for template matching' do
        expect(doc_content).to match(/override.*field.*name|field.*name.*override|replaces.*field.*name/im),
                               'Documentation should explain that field_type overrides the field name used for template matching'
      end
    end

    describe 'key field_options attributes' do
      let(:required_attributes) do
        %w[
          edit_as
          alt_options
          general_selection
          value_attr
          label_attr
          big_select
          include_blank
          format
          pattern
          preset_value
          no_downcase
          calculate_with
          prompt
        ]
      end

      it 'documents all key field_options attributes' do
        undocumented = required_attributes.reject { |attr| doc_content.include?(attr) }
        expect(undocumented).to be_empty,
                                "The following field_options attributes are not documented:\n  #{undocumented.join("\n  ")}"
      end

      it 'documents the edit_as.alt_options attribute' do
        expect(doc_content).to match(/alt_options/),
                               'Documentation should describe the alt_options attribute for inline select options'
      end

      it 'documents the edit_as.big_select attribute' do
        expect(doc_content).to match(/big_select/),
                               'Documentation should describe the big_select attribute for modal selection'
      end

      it 'documents the format attribute for notes fields' do
        expect(doc_content).to match(/format.*(plain|markdown)|markdown.*format/im),
                               'Documentation should describe the format attribute (plain/markdown) for notes fields'
      end

      it 'documents the creatable option' do
        expect(doc_content).to match(/creatable/i),
                               'Documentation should describe the creatable option for typeahead with record creation'
      end

      it 'documents the select_filtering_target option' do
        expect(doc_content).to match(/select_filtering_target/),
                               'Documentation should describe the select_filtering_target option'
      end

      it 'documents the sort_order option' do
        expect(doc_content).to match(/sort_order/),
                               'Documentation should describe the sort_order option for select fields'
      end

      it 'documents the no_assoc option' do
        expect(doc_content).to match(/no_assoc/),
                               'Documentation should describe the no_assoc option'
      end
    end
  end
end
