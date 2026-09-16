# frozen_string_literal: true

# CommonTemplatesHelper#field_options_for spec (issue #1453)
# Covers issue #1453 field option literal handling for new and persisted form objects.

require 'rails_helper'

RSpec.describe CommonTemplatesHelper, type: :helper do
  describe '#field_options_for' do
    it 'preserves a false value and selected value for a new form object' do
      option_type_config = double(field_options: { test1: { value: false } })
      form_object = double(
        option_type_config: option_type_config,
        attributes: { 'test1' => nil },
        persisted?: false
      )

      result = helper.field_options_for(form_object, :test1)

      expect(result[:value]).to be false
      expect(result[:selected]).to be false
    end

    it 'preserves a zero blank value and selected value for a persisted form object' do
      option_type_config = double(field_options: { test1: { blank_value: 0 } })
      form_object = double(
        option_type_config: option_type_config,
        attributes: { 'test1' => nil },
        persisted?: true
      )

      result = helper.field_options_for(form_object, :test1)

      expect(result[:value]).to eq 0
      expect(result[:selected]).to eq 0
    end

    it 'preserves a false blank value and selected value for a persisted form object' do
      option_type_config = double(field_options: { test1: { blank_value: false } })
      form_object = double(
        option_type_config: option_type_config,
        attributes: { 'test1' => nil },
        persisted?: true
      )

      result = helper.field_options_for(form_object, :test1)

      expect(result[:value]).to be false
      expect(result[:selected]).to be false
    end

    it 'does not replace an existing false value with a blank_value' do
      option_type_config = double(field_options: { test1: { blank_value: true } })
      form_object = double(
        option_type_config: option_type_config,
        attributes: { 'test1' => false },
        persisted?: true
      )

      result = helper.field_options_for(form_object, :test1)

      expect(result[:value]).to be false
      expect(result[:selected]).to be false
    end
  end
end
