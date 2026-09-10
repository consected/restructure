# frozen_string_literal: true

require 'rails_helper'

# Spec for Dynamic::FieldEditAs::Handler (issue #1269).
#
# Covers the routing logic in #edit_as_field_types / #translate_to_persistable for
# name_starts_with_yaml_object fields:
# - A field named `yaml_object_*` backed by a text/varchar column routes to
#   Dynamic::FieldEditAs::YamlObject (stores validated YAML text as-is).
# - A field named `yaml_object_*` backed by a json/jsonb column (unsupported/legacy
#   configuration) still routes to Dynamic::FieldEditAs::ColTypeJson, preserving prior
#   behavior as a safety net.
# - A field named `yaml_object_*` backed by an incompatible column type (integer,
#   boolean, etc.) does NOT get the yaml_object transform - the field is treated
#   normally by its column type.
# - An explicit field_options edit_as: field_type: configuration takes precedence over
#   the name-based default in both cases.
# - Fields not matching `yaml_object_*` continue to resolve by column type as before.

RSpec.describe Dynamic::FieldEditAs::Handler do
  def build_object_instance(attribute_names:, column_types:, field_options: {})
    columns_hash = column_types.transform_values { |type| double('Column', type: type) }

    instance_double(
      'UserBase',
      option_type_config: double('OptionTypeConfig', field_options: field_options),
      class: double('Klass', columns_hash: columns_hash),
      attribute_names: attribute_names
    )
  end

  describe '#translate_to_persistable' do
    it 'routes a yaml_object_* field on a text column to YamlObject and stores the YAML text as-is' do
      object_instance = build_object_instance(
        attribute_names: %w[yaml_object_config],
        column_types: { 'yaml_object_config' => :text }
      )
      yaml_text = "key1: value1\n"
      params = { yaml_object_config: yaml_text }

      handler = described_class.new(object_instance, params)

      expect(handler.translate_to_persistable).to eq(yaml_object_config: yaml_text)
    end

    it 'routes a yaml_object_* field on a string column to YamlObject' do
      object_instance = build_object_instance(
        attribute_names: %w[yaml_object_config],
        column_types: { 'yaml_object_config' => :string }
      )
      yaml_text = "- first\n- second\n"
      params = { yaml_object_config: yaml_text }

      handler = described_class.new(object_instance, params)

      expect(handler.translate_to_persistable).to eq(yaml_object_config: yaml_text)
    end

    it 'raises FphsException via YamlObject when the submitted YAML is malformed' do
      object_instance = build_object_instance(
        attribute_names: %w[yaml_object_config],
        column_types: { 'yaml_object_config' => :text }
      )
      params = { yaml_object_config: 'key1: [1, 2' }

      handler = described_class.new(object_instance, params)

      expect { handler.translate_to_persistable }.to raise_error(FphsException, /cannot parse saved value/)
    end

    it 'routes a yaml_object_* field on a jsonb column to ColTypeJson (legacy/safety-net behavior)' do
      object_instance = build_object_instance(
        attribute_names: %w[yaml_object_config],
        column_types: { 'yaml_object_config' => :jsonb }
      )
      params = { yaml_object_config: "key1: value1\n" }

      handler = described_class.new(object_instance, params)

      expect(handler.translate_to_persistable).to eq(yaml_object_config: { 'key1' => 'value1' })
    end

    it 'routes a yaml_object_* field on a json column to ColTypeJson (legacy/safety-net behavior)' do
      object_instance = build_object_instance(
        attribute_names: %w[yaml_object_config],
        column_types: { 'yaml_object_config' => :json }
      )
      params = { yaml_object_config: "- first\n- second\n" }

      handler = described_class.new(object_instance, params)

      expect(handler.translate_to_persistable).to eq(yaml_object_config: %w[first second])
    end

    it 'gives precedence to an explicit edit_as field_type over the yaml_object_ name default' do
      object_instance = build_object_instance(
        attribute_names: %w[yaml_object_config],
        column_types: { 'yaml_object_config' => :text },
        field_options: { yaml_object_config: { edit_as: { field_type: 'multi_editable_list' } } }
      )
      params = { yaml_object_config: "line1\nline2" }

      handler = described_class.new(object_instance, params)

      expect(handler.translate_to_persistable).to eq(yaml_object_config: %w[line1 line2])
    end

    it 'does not apply an explicit yaml_object transform to an unsupported column type' do
      object_instance = build_object_instance(
        attribute_names: %w[yaml_object_count],
        column_types: { 'yaml_object_count' => :integer },
        field_options: { yaml_object_count: { edit_as: { field_type: 'yaml_object' } } }
      )
      params = { yaml_object_count: "key1: value1\n" }

      handler = described_class.new(object_instance, params)

      expect(handler.translate_to_persistable).to eq({})
    end

    it 'does not apply yaml_object transform to a yaml_object_* field on an integer column' do
      object_instance = build_object_instance(
        attribute_names: %w[yaml_object_count],
        column_types: { 'yaml_object_count' => :integer }
      )
      params = { yaml_object_count: '42' }

      handler = described_class.new(object_instance, params)

      expect(handler.translate_to_persistable).to eq({})
    end

    it 'does not apply yaml_object transform to a yaml_object_* field on a boolean column' do
      object_instance = build_object_instance(
        attribute_names: %w[yaml_object_flag],
        column_types: { 'yaml_object_flag' => :boolean }
      )
      params = { yaml_object_flag: 'true' }

      handler = described_class.new(object_instance, params)

      expect(handler.translate_to_persistable).to eq({})
    end

    it 'does not affect fields that do not start with yaml_object_' do
      object_instance = build_object_instance(
        attribute_names: %w[plain_config],
        column_types: { 'plain_config' => :string }
      )
      params = { plain_config: 'some text' }

      handler = described_class.new(object_instance, params)

      expect(handler.translate_to_persistable).to eq({})
    end

    it 'does not include a yaml_object_* field in the persistable hash when it is absent ' \
       'from submitted params (partial update safety)' do
      object_instance = build_object_instance(
        attribute_names: %w[yaml_object_config],
        column_types: { 'yaml_object_config' => :text }
      )

      handler = described_class.new(object_instance, {})

      expect(handler.translate_to_persistable).to eq({})
    end

    it 'does not include a col_type_json field in the persistable hash when it is absent ' \
       'from submitted params (partial update safety)' do
      object_instance = build_object_instance(
        attribute_names: %w[settings],
        column_types: { 'settings' => :jsonb }
      )

      handler = described_class.new(object_instance, {})

      expect(handler.translate_to_persistable).to eq({})
    end

    it 'still translates a yaml_object_* field present in submitted params alongside other omitted fields' do
      object_instance = build_object_instance(
        attribute_names: %w[yaml_object_config other_field],
        column_types: { 'yaml_object_config' => :text, 'other_field' => :string }
      )
      yaml_text = "key1: value1\n"
      params = { yaml_object_config: yaml_text }

      handler = described_class.new(object_instance, params)

      expect(handler.translate_to_persistable).to eq(yaml_object_config: yaml_text)
    end
  end
end
