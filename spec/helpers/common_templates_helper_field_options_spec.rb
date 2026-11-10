# frozen_string_literal: true

# CommonTemplatesHelper#field_options_for specs (issues #1453, #1456, #1457)
# Issue #1460 specs also verify select field options become HTML attributes
# without leaking select-only or edit configuration keys onto the select.
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

  describe '#html_options_for_field_options' do
    it 'separates select options and field configuration from HTML attributes' do
      field_options = {
        class: 'configured-select',
        placeholder: 'Choose a person',
        disabled: true,
        include_blank: true,
        selected: 'person-1',
        prompt: 'Choose',
        include_hidden: false,
        edit_as: { big_select: true },
        format: 'example',
        data: { custom_attribute: 'custom-value' }
      }

      result = helper.html_options_for_field_options(field_options, { data: { attr_name: 'person' } })

      expect(result).to include(class: 'configured-select', placeholder: 'Choose a person', disabled: true)
      expect(result[:data]).to eq(attr_name: 'person', custom_attribute: 'custom-value')
      expect(result).not_to include(:include_blank, :selected, :prompt, :include_hidden, :edit_as, :format)
    end

    it 'appends a configured class to a default class rather than replacing it' do
      result = helper.html_options_for_field_options({ class: 'extra' }, { class: 'form-control input-sm' })

      expect(result[:class]).to eq 'form-control input-sm extra'
    end

    it 'keeps disabled choice arrays in the select options rather than HTML attributes' do
      result = helper.html_options_for_field_options({ disabled: %w[person-1 person-2] })

      expect(result).not_to have_key(:disabled)
    end
  end

  describe 'select edit field partials HTML options (issue #1460)' do
    # Each changed partial with the field name that routes to it
    partial_field_names = {
      'name_is_protocol_id' => 'protocol_id',
      'name_starts_with_multi' => 'multi_things',
      'name_starts_with_pick_multiple_records_from_table' => 'pick_multiple_records_from_table_test_items',
      'name_starts_with_select' => 'select_things',
      'name_starts_with_select_record_from' => 'select_record_from_people',
      'name_starts_with_select_record_from_table' => 'select_record_from_table_people',
      'name_starts_with_select_record_id_from' => 'select_record_id_from_people',
      'name_starts_with_select_record_id_from_table' => 'select_record_id_from_table_people',
      'name_starts_with_select_user_with_role' => 'select_user_with_role_reviewer',
      'name_starts_with_tag_select' => 'tag_select_things',
      'name_starts_with_tag_select_record_from' => 'tag_select_record_from_people',
      'name_starts_with_tag_select_record_from_table' => 'tag_select_record_from_table_people',
      'name_starts_with_tag_select_record_id_from' => 'tag_select_record_id_from_people',
      'name_starts_with_tag_select_users_with_role' => 'tag_select_users_with_role_reviewer'
    }

    before do
      test_item_class = Class.new do
        def self.all
          self
        end

        def self.order(*)
          [Struct.new(:data, :table_key, :id).new('Ada', 'ada', 1)]
        end
      end
      stub_const('TestItem', test_item_class)

      user_scope = double(users: double(not_template: double(all: [{ 'email' => 'a@example.com' }.tap { |u| u.define_singleton_method(:email) { self['email'] } }])))
      allow(Admin::UserRole).to receive_message_chain(:active, :where).and_return(user_scope)
      allow(helper).to receive(:current_user).and_return(double(app_type: nil))

      # These helpers live in other modules or controllers, so define them on the helper directly
      {
        list_record_data_for_select: ['Person', [%w[Ada ada]]],
        edit_field_label: '',
        general_selection_name: 'test',
        general_selection: [['Ada', 'ada', nil, nil, nil, nil, nil]],
        general_selection_missing_fallback?: false,
        protocol_array_without_updates: [['Protocol', 1]]
      }.each do |name, value|
        helper.define_singleton_method(name) { |*_args, **_kwargs| value }
      end
    end

    partial_field_names.each do |partial, field_name|
      it "renders field_options disabled and class on the select element for #{partial}" do
        field_name_sym = field_name.to_sym
        option_type_config = double(
          field_options: {
            field_name_sym => {
              disabled: true,
              class: 'configured-select',
              edit_as: { value_attr: :data }
            }
          }
        )
        form_object = double(
          option_type_config: option_type_config,
          attributes: { field_name => nil },
          persisted?: false,
          field_name_sym => nil
        )
        allow(form_object).to receive(:[]).and_return(nil)
        form = ActionView::Helpers::FormBuilder.new(:record, form_object, helper, {})

        rendered = helper.render(
          partial: "common_templates/edit_fields/#{partial}",
          locals: {
            form:,
            field_name:,
            field_name_sym:,
            form_object_instance: form_object,
            labels: {},
            form_object_item_type_us: 'test_model'
          }
        )

        select_tag = rendered[/<select[^>]*>/]
        expect(select_tag).to include('disabled="disabled"')
        expect(select_tag).to match(/class="[^"]*configured-select[^"]*"/)
        expect(select_tag).not_to include('edit_as=')
      end
    end
  end
end
