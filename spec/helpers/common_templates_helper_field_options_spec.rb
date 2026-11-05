# frozen_string_literal: true

# CommonTemplatesHelper#field_options_for specs (issues #1453, #1456, #1457)
# Covers field option literal handling, pass-through attributes, and issue #1457
# regressions where memoized options leak between fields or form objects.

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

    it 'forwards disabled and an arbitrary pass-through key to the rendered field (issue #1456)' do
      field_options = OptionConfigs::ExtraOptionConfigs::FieldOptions.new(
        test1: { disabled: true, placeholder: 'Pick one', some_random_html_attr: 'foo' }
      )
      option_type_config = double(field_options: field_options)
      form_object = double(
        option_type_config: option_type_config,
        attributes: { 'test1' => nil },
        persisted?: false
      )

      result = helper.field_options_for(form_object, :test1)

      expect(result[:disabled]).to be true
      expect(result[:placeholder]).to eq 'Pick one'
      expect(result[:some_random_html_attr]).to eq 'foo'
    end

    it "returns each field's own configuration across sequential calls on one form object (issue #1457)" do
      option_type_config = double(
        field_options: {
          first_field: {
            selected: 'first-selected',
            format: 'first-format',
            edit_as: { field_type: 'first-field-type' }
          },
          second_field: {
            selected: 'second-selected',
            format: 'second-format',
            edit_as: { field_type: 'second-field-type' }
          }
        }
      )
      form_object = double(option_type_config: option_type_config)

      first_result = helper.field_options_for(form_object, :first_field)
      second_result = helper.field_options_for(form_object, :second_field)

      expect(first_result).to eq(
        selected: 'first-selected',
        format: 'first-format',
        edit_as: { field_type: 'first-field-type' }
      )
      expect(second_result).to eq(
        selected: 'second-selected',
        format: 'second-format',
        edit_as: { field_type: 'second-field-type' }
      )
    end

    it "returns each form object's own configuration across sequential calls for one field (issue #1457)" do
      first_form_object = double(
        option_type_config: double(
          field_options: {
            status: {
              selected: 'first-selected',
              format: 'first-format',
              edit_as: { field_type: 'first-field-type' }
            }
          }
        )
      )
      second_form_object = double(
        option_type_config: double(
          field_options: {
            status: {
              selected: 'second-selected',
              format: 'second-format',
              edit_as: { field_type: 'second-field-type' }
            }
          }
        )
      )

      first_result = helper.field_options_for(first_form_object, :status)
      second_result = helper.field_options_for(second_form_object, :status)

      expect(first_result).to eq(
        selected: 'first-selected',
        format: 'first-format',
        edit_as: { field_type: 'first-field-type' }
      )
      expect(second_result).to eq(
        selected: 'second-selected',
        format: 'second-format',
        edit_as: { field_type: 'second-field-type' }
      )
    end

    it "returns each field's own computed value/selected across sequential calls on one form object (issue #1457)" do
      option_type_config = double(
        field_options: {
          first_field: { value: 'first-value' },
          second_field: { value: 'second-value' }
        }
      )
      form_object = double(
        option_type_config: option_type_config,
        attributes: { 'first_field' => nil, 'second_field' => nil },
        persisted?: false
      )

      first_result = helper.field_options_for(form_object, :first_field)
      second_result = helper.field_options_for(form_object, :second_field)

      expect(first_result[:value]).to eq 'first-value'
      expect(first_result[:selected]).to eq 'first-value'
      expect(second_result[:value]).to eq 'second-value'
      expect(second_result[:selected]).to eq 'second-value'
    end

    it 'recomputes for the same form object and field when reset: true is passed (issue #1457)' do
      option_type_config = double(field_options: { test1: { value: 'first-value' } })
      form_object = double(
        option_type_config: option_type_config,
        attributes: { 'test1' => nil },
        persisted?: false
      )

      first_result = helper.field_options_for(form_object, :test1)
      expect(first_result[:value]).to eq 'first-value'

      allow(option_type_config).to receive(:field_options).and_return(test1: { value: 'second-value' })

      cached_result = helper.field_options_for(form_object, :test1)
      expect(cached_result[:value]).to eq 'first-value'

      reset_result = helper.field_options_for(form_object, :test1, reset: true)
      expect(reset_result[:value]).to eq 'second-value'
    end
  end
end
