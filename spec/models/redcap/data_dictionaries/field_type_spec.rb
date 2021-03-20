# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::DataDictionaries::FieldType, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :example do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
  end

  it 'generates produces sensible field type definitions' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    forms = rc.redcap_data_dictionary.forms
    expect(forms).to be_present

    form = forms.first.last
    fields = form.fields
    expect(fields).to be_present

    field_type = fields.first.last.field_type
    expect(field_type).to be_a Redcap::DataDictionaries::FieldType

    expect(field_type.presentation_type).to eq 'text [none]'
    expect(field_type.default_variable_type).to eq 'plain text'
  end

  it 'allows the field to be correctly cast to a real type' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    forms = rc.redcap_data_dictionary.forms
    expect(forms).to be_present

    form = forms.first.last
    fields = form.fields
    expect(fields).to be_present

    field_type = fields.first.last.field_type
    expect(field_type).to be_a Redcap::DataDictionaries::FieldType

    field_type = form.fields_of_variable_type('date').first.last.field_type
    expect(field_type.cast_value_to_real('1998-04-16')).to be_a Date
    field_type = form.fields_of_variable_type('date time').first.last.field_type
    expect(field_type.cast_value_to_real('2019-04-16 11:23:04')).to be_a DateTime
    field_type = form.fields_of_variable_type('categorical').first.last.field_type
    expect(field_type.cast_value_to_real('some value')).to be_a String

    form = forms[:test]
    fields = form.fields

    field_type = form.fields_of_variable_type('dichotomous').first.last.field_type
    expect(field_type.cast_value_to_real('1')).to be_a TrueClass
  end
end
