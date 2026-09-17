# frozen_string_literal: true

require 'rails_helper'

# Spec for the yaml_object_ result field Handlebars condition in
# common_templates/_common_template_result_fields.html.erb (issue #1269).
#
# yaml_object_* fields are backed by a text/varchar column, so the stored `this_value`
# arrives as plain YAML text (a String), not an already-parsed Hash/Array. The Handlebars
# condition for these fields must parse that text (via the `yaml_parse` helper - see
# handlebars-helpers.js) and then reuse the existing structured/collapsible object view
# used for real json/jsonb object fields (the 'typeof object' branch), rather than
# duplicating that rendering markup.
#
# Tests verify:
# - The template source contains the '^yaml_object_' Handlebars field_type condition.
# - The yaml_object_ condition appears BEFORE the generic 'typeof' 'object' condition,
#   so it takes precedence for fields with that name prefix.
# - The yaml_object_ condition appears BEFORE all suffix-based handlers (_notes$,
#   _description$, _details$), so e.g. yaml_object_notes is parsed as YAML rather than
#   rendered as raw text by a suffix handler.
# - The yaml_object_ condition parses this_value via the yaml_parse helper.
# - The yaml_object_ condition delegates to the same partial (common_template_result_field)
#   with field_type cleared, so the recursive call cannot re-match '^yaml_object_' (avoiding
#   infinite recursion) and instead falls through to the 'typeof object' rendering.

RSpec.describe 'common_templates result fields yaml_object_ condition', type: :view do
  let(:template_path) do
    Rails.root.join('app', 'views', 'common_templates', '_common_template_result_fields.html.erb')
  end

  let(:template_source) { File.read(template_path) }

  it 'contains a Handlebars condition matching field_type starting with yaml_object_' do
    expect(template_source).to match(/\^yaml_object_/)
  end

  it 'places the yaml_object_ condition before the typeof object condition' do
    yaml_object_pos = template_source.index(/\^yaml_object_/)
    typeof_object_pos = template_source.index("'typeof' 'object'")

    expect(yaml_object_pos).to be < typeof_object_pos,
                               'yaml_object_ condition must appear before the typeof object condition'
  end

  it 'places the yaml_object_ condition before all suffix-based handlers (_notes, _description, _details)' do
    yaml_object_pos = template_source.index(/\^yaml_object_/)
    notes_pos = template_source.index('"_notes$"')
    description_pos = template_source.index('"_description$"')
    details_pos = template_source.index('"_details$"')

    expect(yaml_object_pos).to be < notes_pos,
                               'yaml_object_ condition must appear before the _notes$ suffix handler'
    expect(yaml_object_pos).to be < description_pos,
                               'yaml_object_ condition must appear before the _description$ suffix handler'
    expect(yaml_object_pos).to be < details_pos,
                               'yaml_object_ condition must appear before the _details$ suffix handler'
  end

  it 'parses this_value via the yaml_parse helper within the yaml_object_ condition block' do
    yaml_object_pos = template_source.index(/\^yaml_object_/)
    window = template_source[yaml_object_pos, 400]

    expect(window).to include('(yaml_parse this_value)'),
                      'yaml_object_ block must parse this_value with the yaml_parse helper'
  end

  it 'delegates to common_template_result_field with field_type cleared to avoid infinite recursion' do
    yaml_object_pos = template_source.index(/\^yaml_object_/)
    window = template_source[yaml_object_pos, 400]

    expect(window).to include('common_template_result_field'),
                      'yaml_object_ block must delegate to the common_template_result_field partial'
    expect(window).to include('field_type=""'),
                      'yaml_object_ block must clear field_type on the recursive call to avoid infinite recursion'
  end
end
