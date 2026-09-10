# frozen_string_literal: true

require 'rails_helper'

# View spec for common_templates/edit_fields/_name_starts_with_yaml_object partial (issue #1269).
#
# This partial provides a YAML codemirror editor for fields whose names begin with
# 'yaml_object_'. The field is backed ONLY by a text/varchar database column - the
# stored value IS the YAML text, so it is displayed directly with no hash/array conversion.
# On save, Dynamic::FieldEditAs::Handler routes yaml_object_* fields (on non-json/jsonb
# columns) to Dynamic::FieldEditAs::YamlObject, which validates and stores the YAML text
# as-is.
#
# Tests verify:
# - The partial renders a textarea with YAML codemirror configuration for a stored YAML string.
# - The textarea has the correct CSS classes and data attributes for the codemirror editor.
# - A stored YAML text value (Hash-shaped) is displayed unchanged, without re-encoding it.
# - A stored YAML text value (Array-shaped) is displayed unchanged.
# - A nil/blank value renders an empty editor without raising errors.

RSpec.describe 'common_templates/edit_fields/_name_starts_with_yaml_object', type: :view do
  let(:field_name_sym) { :yaml_object_config }
  let(:field_name) { 'yaml_object_config' }
  let(:form_object_item_type_us) { 'dynamic_model__test_records' }
  let(:labels) { {} }

  let(:form_object_instance) do
    obj = double('FormObjectInstance')
    allow(obj).to receive(:[]).with('yaml_object_config').and_return(stored_value)
    allow(obj).to receive(:attributes).and_return({ 'yaml_object_config' => stored_value })
    obj
  end

  let(:form) do
    f = double('FormBuilder')
    allow(f).to receive(:text_area) do |field, opts|
      "<textarea name=\"#{field}\" class=\"#{opts[:class]}\" data-code-editor-type=\"#{opts.dig(:data, :code_editor_type)}\">#{opts[:value]}</textarea>".html_safe
    end
    allow(f).to receive(:object).and_return(form_object_instance)
    f
  end

  before do
    # Stub helpers that are called by the partial
    without_partial_double_verification do
      allow(view).to receive(:field_options_for).and_return({})
      allow(view).to receive(:edit_field_label) do |_form, _sym, _labels, _pattern = nil|
        '<label>Yaml object config</label>'.html_safe
      end
    end
  end

  def render_partial
    render partial: 'common_templates/edit_fields/name_starts_with_yaml_object',
           locals: {
             form: form,
             field_name_sym: field_name_sym,
             field_name: field_name,
             form_object_item_type_us: form_object_item_type_us,
             form_object_instance: form_object_instance,
             labels: labels,
             locals: {}
           }
  end

  context 'when the field holds an existing YAML text value' do
    let(:stored_value) { "key1: value1\nkey2: 42\n" }

    it 'renders a textarea with the YAML codemirror CSS class' do
      render_partial

      expect(rendered).to include('code-editor-yaml')
    end

    it 'sets data-code-editor-type to yaml' do
      render_partial

      expect(rendered).to include('data-code-editor-type="yaml"')
    end

    it 'displays the stored YAML text unchanged, without re-encoding it' do
      render_partial

      expect(rendered).to include('key1: value1')
      expect(rendered).to include('key2: 42')
      expect(rendered).not_to include("--- '")
    end
  end

  context 'when the field holds an existing YAML array text value' do
    let(:stored_value) { "- first\n- second\n" }

    it 'displays the stored YAML text unchanged' do
      render_partial

      expect(rendered).to include('- first')
      expect(rendered).to include('- second')
    end
  end

  context 'when the field holds a nil value' do
    let(:stored_value) { nil }

    it 'renders without error' do
      expect { render_partial }.not_to raise_error
    end

    it 'renders a textarea with YAML codemirror CSS class' do
      render_partial

      expect(rendered).to include('code-editor-yaml')
    end
  end
end
