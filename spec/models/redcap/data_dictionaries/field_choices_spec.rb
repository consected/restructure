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

  def check_all_choices(form)
    all_choices_fields = form.fields_of_type(:dropdown).merge(
      form.fields_of_type(:radio)
    ).merge(
      form.fields_of_type(:checkbox)
    )

    expect(Datadic::Choice.active.count).to be_positive

    dd = form.data_dictionary
    expect(all_choices_fields.length).to be_present

    count_choices = 0

    all_choices_fields.each do |_k, field|
      base_attrs = {
        source_name: dd.source_name,
        source_type: :redcap,
        form_name: field.form.name,
        field_name: field.name,
        redcap_data_dictionary_id: form.data_dictionary
      }

      expect(field.field_choices.choices).to be_present

      field.field_choices_plain_text.each do |choice|
        label = choice.last
        value = choice.first
        attrs = base_attrs.merge(label: label, value: value)
        res = Datadic::Choice.active.where(attrs).first

        expect(res).to be_a Datadic::Choice
        count_choices += 1
      end
    end

    # Expect the number of items for this data dictionary in this form to match the number
    # of choices we iterated through based on the metadata definition
    expect(
      Datadic::Choice.active
        .where(form_name: form.name,
               redcap_data_dictionary_id: form.data_dictionary)
        .count
    ).to eq count_choices
  end

  it 'generates instances representing the forms configuration' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    forms = rc.redcap_data_dictionary.forms
    expect(forms).to be_present

    form = forms.first.last
    fields = form.fields
    expect(fields).to be_present

    field_type = fields.first.last.field_type
    expect(field_type).to be_a Redcap::DataDictionaries::FieldType

    dropdown_field = form.fields_of_type(:dropdown).first.last
    expect(dropdown_field.field_choices.choices).to be_present
  end

  it 'updates the data dictionary choices' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    expect(rc.redcap_data_dictionary.captured_metadata).to eq rc.api_client.metadata

    forms = rc.redcap_data_dictionary.forms
    form = forms.first.last

    expect(Datadic::Choice.active.count).to be_positive

    check_all_choices form

    # Make a change to a datadic choices entry then force a refresh to check it gets updated
    fd = Datadic::Choice.active.where(redcap_data_dictionary_id: form.data_dictionary).first

    label = fd.label

    fd.update!(label: "Changed #{label}", current_admin: @admin)

    # Make sure it changed in the DB
    expect(Datadic::Choice.active.where(redcap_data_dictionary_id: form.data_dictionary).first.label).not_to eq label

    rc.notes = "#{rc.notes} more details"
    rc.force_refresh = true
    rc.save!

    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    forms = rc.redcap_data_dictionary.forms
    form = forms.first.last

    check_all_choices form
  end
end
