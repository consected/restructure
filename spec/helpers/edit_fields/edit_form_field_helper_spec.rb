# frozen_string_literal: true

# EditFormFieldHelper Spec
#
# Covers helper behavior for:
# - Missing general selection configs in report-backed edit fields.
#   - Falls back to default text input and logs a warning for arbitrary-table reports.
#   - Preserves strict missing-config error behavior for protected view-handler item types.
# - calculate_with JavaScript generation in edit_form_field_helper.rb.
#   - javascript_tag with heredoc block must produce valid JavaScript (not HTML-encoded).
#   - Verifies that single quotes in the heredoc are NOT html-entity-encoded to &#39;.
#   - Verifies that JSON content (containing double quotes) is NOT html-entity-encoded to &quot;.
#   - Regression test for bug where Rails 7.2 capture helper HTML-escaped plain String
#     return values from javascript_tag blocks, producing invalid <script> content
#     (e.g. _fpa.calculate_with[&#39;field&#39;] instead of _fpa.calculate_with['field']).
# - name_starts_with_yaml_object edit field dispatch (issue #1269).
#   - Fields whose names begin with 'yaml_object_' must be dispatched to the
#     _name_starts_with_yaml_object partial (YAML codemirror editor).

require 'rails_helper'

RSpec.describe EditFields::EditFormFieldHelper, type: :helper do
  describe 'missing general selection handling for report edit fields' do
    let(:form_object_instance) do
      instance_double(
        'ReportBackedModel',
        model_data_type: :report,
        class: double(name: 'Report::ArbitraryTable', table_name: 'arbitrary_table_records'),
        send: nil
      )
    end

    let(:locals) { { locals: {} } }

    before do
      allow(helper).to receive(:field_options_for).and_return({})
      allow(helper).to receive(:is_current_admin_sample?).and_return(false)
      allow(helper).to receive(:respond_to?).and_call_original
      allow(helper).to receive(:respond_to?).with('rank_options').and_return(false)
      allow(helper).to receive(:general_selection_prefix_name).and_return('dynamic_model__arbitrary_table_records')
      allow(Classification::GeneralSelection).to receive(:exists_for?).and_return(true)

      allow(helper).to receive(:render) do |args|
        partial = args[:partial]
        case partial
        when 'common_templates/edit_fields/is_general_selection'
          'GS_FIELD'
        when 'common_templates/edit_fields/default'
          'DEFAULT_FIELD'
        else
          false
        end
      end
    end

    it 'falls back to default text field and logs a warning for arbitrary-table report items' do
      allow(helper).to receive(:general_selection).and_return(nil)
      allow(Rails.logger).to receive(:warn)

      result = helper.edit_form_field(
        form: double('FormBuilder'),
        field_name_sym: :rank,
        field_name: 'rank',
        column_type: :string,
        general_selection_name: 'dynamic_model__arbitrary_table_records',
        form_object_instance: form_object_instance,
        form_object_item_type_us: 'dynamic_model__arbitrary_table_records',
        caption_before: {},
        labels: {},
        locals:
      )

      expect(result).to eq('DEFAULT_FIELD')
      expect(Rails.logger).to have_received(:warn).with(/missing general selection/i)
    end

    it 'retains missing-config exception behavior for protected view handler item types' do
      allow(helper).to receive(:general_selection).and_return(nil)
      allow(helper).to receive(:report_item_type_requires_general_selection_error?).and_return(true)

      expect do
        helper.edit_form_field(
          form: double('FormBuilder'),
          field_name_sym: :rank,
          field_name: 'rank',
          column_type: :string,
          general_selection_name: 'dynamic_model__arbitrary_table_records',
          form_object_instance: form_object_instance,
          form_object_item_type_us: 'dynamic_model__arbitrary_table_records',
          caption_before: {},
          labels: {},
          locals:
        )
      end.to raise_error(FphsException, /general selection/i)
    end
  end

  describe 'calculate_with script generation' do
    # Simulate what edit_form_field_helper.rb does for the calculate_with option:
    #   javascript_tag(nonce: true) do
    #     <<~END_JS.html_safe
    #       _fpa.calculate_with['#{field_name_sym}'] = #{cw.to_json.html_safe};
    #       _fpa.utils.calc_field('#{field_name_sym}', '#{form_object_type}');
    #     END_JS
    #   end
    #
    # Without .html_safe on the heredoc, Rails 7.2's capture helper HTML-escapes
    # plain Strings, turning ' into &#39; and " into &quot; inside the <script> tag.

    before do
      # Stub content_security_policy_nonce since we're not in a real request context
      allow(helper).to receive(:content_security_policy_nonce).and_return('test-nonce')
    end

    it 'produces valid JavaScript without HTML entities when heredoc is marked html_safe' do
      field_name = 'tmoca_score'
      model_type = 'dynamic_model__play_ipa_phone_screen_tmoca_scores_rec'
      calculate_with = { 'sum' => %w[field_a field_b field_c] }

      result = helper.javascript_tag(nonce: true) do
        <<~END_JS.html_safe
          _fpa.calculate_with = _fpa.calculate_with || {};
          var cwdef = _fpa.calculate_with['#{field_name}'] = #{calculate_with.to_json.html_safe};
          _fpa.utils.calc_field('#{field_name}', '#{model_type}');
        END_JS
      end

      # The script tag content must contain raw JavaScript, not HTML entities
      expect(result).to include("_fpa.calculate_with['tmoca_score']")
      expect(result).to include('"sum":["field_a","field_b","field_c"]')
      expect(result).to include("_fpa.utils.calc_field('tmoca_score'")

      # Must NOT contain HTML entities inside the script tag
      expect(result).not_to include('&#39;')
      expect(result).not_to include('&quot;')
      expect(result).not_to include('&amp;')
    end

    it 'would produce HTML-encoded content without html_safe (demonstrating the bug)' do
      field_name = 'tmoca_score'
      calculate_with = { 'sum' => %w[field_a field_b] }

      # Without .html_safe, Rails 7.2's capture helper HTML-escapes the string
      result = helper.javascript_tag(nonce: true) do
        <<~END_JS
          _fpa.calculate_with['#{field_name}'] = #{calculate_with.to_json};
        END_JS
      end

      # This demonstrates the bug: the content gets HTML-entity-encoded
      expect(result).to include('&#39;'), 'Expected HTML-encoded single quotes (demonstrating the bug)'
      expect(result).to include('&quot;'), 'Expected HTML-encoded double quotes (demonstrating the bug)'
    end
  end

  describe 'name_starts_with_yaml_object dispatch' do
    let(:form_object_instance) do
      instance_double(
        'DynamicModel::YamlTestRecord',
        model_data_type: :dynamic_model,
        class: double(name: 'DynamicModel::YamlTestRecord', table_name: 'yaml_test_records'),
        send: nil
      )
    end

    let(:locals) { { locals: {} } }
    let(:rendered_partials) { [] }

    before do
      allow(helper).to receive(:field_options_for).and_return({})
      allow(helper).to receive(:is_current_admin_sample?).and_return(false)
      allow(helper).to receive(:respond_to?).and_call_original
      allow(helper).to receive(:general_selection_prefix_name).and_return('dynamic_model__yaml_test_records')
      allow(Classification::GeneralSelection).to receive(:exists_for?).and_return(false)

      # Reset memoized file list so the new partial is discovered
      helper.instance_variable_set(:@f_names, nil)

      allow(helper).to receive(:render) do |args|
        partial = args[:partial]
        rendered_partials << partial
        "RENDERED:#{partial}"
      end
    end

    it 'dispatches to name_starts_with_yaml_object partial for a yaml_object_ prefixed field' do
      result = helper.edit_form_field(
        form: double('FormBuilder'),
        field_name_sym: :yaml_object_config,
        field_name: 'yaml_object_config',
        column_type: :string,
        general_selection_name: 'dynamic_model__yaml_test_records',
        form_object_instance: form_object_instance,
        form_object_item_type_us: 'dynamic_model__yaml_test_records',
        caption_before: {},
        labels: {},
        locals:
      )

      expect(rendered_partials).to include('common_templates/edit_fields/name_starts_with_yaml_object')
      expect(result).to include('name_starts_with_yaml_object')
    end

    it 'does not dispatch to name_starts_with_yaml_object partial for non-yaml_object_ prefixed fields' do
      helper.edit_form_field(
        form: double('FormBuilder'),
        field_name_sym: :other_config,
        field_name: 'other_config',
        column_type: :string,
        general_selection_name: 'dynamic_model__yaml_test_records',
        form_object_instance: form_object_instance,
        form_object_item_type_us: 'dynamic_model__yaml_test_records',
        caption_before: {},
        labels: {},
        locals:
      )

      expect(rendered_partials).not_to include('common_templates/edit_fields/name_starts_with_yaml_object')
    end

    it 'does not dispatch to name_starts_with_yaml_object partial for a yaml_object_ field with jsonb column type' do
      helper.edit_form_field(
        form: double('FormBuilder'),
        field_name_sym: :yaml_object_config,
        field_name: 'yaml_object_config',
        column_type: :jsonb,
        general_selection_name: 'dynamic_model__yaml_test_records',
        form_object_instance: form_object_instance,
        form_object_item_type_us: 'dynamic_model__yaml_test_records',
        caption_before: {},
        labels: {},
        locals:
      )

      expect(rendered_partials).not_to include('common_templates/edit_fields/name_starts_with_yaml_object')
      # Should fall through to column_type_jsonb partial instead
      expect(rendered_partials).to include('common_templates/edit_fields/column_type_jsonb')
    end

    it 'does not dispatch to name_starts_with_yaml_object partial for a yaml_object_ field with json column type' do
      helper.edit_form_field(
        form: double('FormBuilder'),
        field_name_sym: :yaml_object_settings,
        field_name: 'yaml_object_settings',
        column_type: 'json',
        general_selection_name: 'dynamic_model__yaml_test_records',
        form_object_instance: form_object_instance,
        form_object_item_type_us: 'dynamic_model__yaml_test_records',
        caption_before: {},
        labels: {},
        locals:
      )

      expect(rendered_partials).not_to include('common_templates/edit_fields/name_starts_with_yaml_object')
      expect(rendered_partials).to include('common_templates/edit_fields/column_type_json')
    end

    it 'dispatches to name_starts_with_yaml_object partial when column_type is a string "string"' do
      helper.edit_form_field(
        form: double('FormBuilder'),
        field_name_sym: :yaml_object_config,
        field_name: 'yaml_object_config',
        column_type: 'string',
        general_selection_name: 'dynamic_model__yaml_test_records',
        form_object_instance: form_object_instance,
        form_object_item_type_us: 'dynamic_model__yaml_test_records',
        caption_before: {},
        labels: {},
        locals:
      )

      expect(rendered_partials).to include('common_templates/edit_fields/name_starts_with_yaml_object')
    end
  end
end
