# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::DataDictionaries::Field, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :example do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
  end

  it 'generates fields configuration' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    dd = rc.redcap_data_dictionary
    res = dd.forms[:q2_survey].fields
    expect(res).to be_a Hash
  end

  it 'adds a Datadic::Variable record for the field' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    dd = rc.redcap_data_dictionary
    dd.forms[:q2_survey].fields[:dob]

    v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: :dob).first
    expect(v).not_to be_nil

    expect(v.variable_name).to eq 'dob'
    expect(v.variable_type).to eq 'date'
    expect(v.presentation_type).to eq 'text [date_mdy]'
    expect(v.position).to eq 1
    expect(v.section_id).to be_nil
    expect(v.sub_section_id).to be_nil
  end

  it 'adds a Datadic::Variable record for the form_complete field' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    dd = rc.redcap_data_dictionary

    v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: 'q2_survey_complete').first
    expect(v).not_to be_nil

    expect(v.variable_name).to eq 'q2_survey_complete'
    expect(v.variable_type).to eq 'redcap status'
    expect(v.presentation_type).to eq 'form_complete [integer]'
    expect(v.annotation).to eq 'Redcap values: 0 Incomplete, 1 Unverified, 2 Complete'
  end

  it 'automatically gets the list of "checkbox" type fields' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    forms = rc.redcap_data_dictionary.forms
    form = forms.first.last

    field = form.fields_of_type(:text).first.last
    expect(field.checkbox_choice_fields).to be_nil

    check_fields = form.fields_of_type(:checkbox)
    check_field = check_fields.first.last
    expect(check_field.checkbox_choice_fields).to be_a Array
    expect(check_field.checkbox_choice_fields.first).to match(/^#{check_field.name}___.+$/)
  end

  it 'gets a full list of fields to be persisted to' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    forms = rc.redcap_data_dictionary.forms
    form = forms.first.last

    fs = Redcap::DataDictionaries::Field.all_retrievable_fields(form)

    expect(fs.keys).to eq %i[record_id dob current_weight smoketime___pnfl smoketime___dnfl smoketime___anfl smoke_start smoke_stop
                             smoke_curr demog_date ncmedrec_add ladder_wealth ladder_comm born_address twelveyrs_address
                             othealth___complete othealth_date q2_survey_complete]

    form = forms[forms.keys.last]
    fs = Redcap::DataDictionaries::Field.all_retrievable_fields(form)

    expect(fs.keys).to eq %i[sdfsdaf___0 sdfsdaf___1 sdfsdaf___2
                             rtyrtyrt___0 rtyrtyrt___1 rtyrtyrt___2
                             test_field test_phone i57 f57 dd yes_or_no test_complete]
  end

  it 'automatically populates relationship between "checkbox" type fields' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    dd = rc.redcap_data_dictionary
    forms = dd.forms
    form = forms.first.last

    field = form.fields_of_type(:text).first.last
    expect(field.checkbox_choice_fields).to be_nil

    check_fields = form.fields_of_type(:checkbox)
    check_field = check_fields.first.last

    # The individual choice fields should list the main field as #equivalent_to
    # and should have an appropriate presentation_type
    check_field.checkbox_choice_fields.each do |f|
      v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: f).first
      expect(v.equivalent_to).not_to be_nil
      expect(v.presentation_type).to eq 'checkbox [choice]'
    end

    # The main field should list the individual choice fields as #also_equivalent_to
    v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: check_field.name).first
    expect(v.also_equivalent_to.count).to be_positive
  end

  it 'handles changes to "checkbox" type fields' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    dd = rc.redcap_data_dictionary
    dd.current_admin = @admin
    forms = dd.forms
    form = forms.first.last

    check_fields = form.fields_of_type(:checkbox)
    check_field = check_fields.first.last

    # Start by checking the choices have initial values

    # The individual choice fields should list the main field as #equivalent_to
    check_field.checkbox_choice_fields.each do |f|
      v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: f).first
      expect(v.equivalent_to).not_to be_nil
    end

    # The main field should list the individual choice fields as #also_equivalent_to
    v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: check_field.name).first
    expect(v.also_equivalent_to.count).to be_positive

    # Now change the item and check the changes are applied

    # First, add a record to the dictionary that claims to be equivalent, but does not match the choices format ___xyz
    # so we can ensure it doesn't get damaged by the subsequent actions

    main_entry = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: check_field.name).first
    main_entry.current_admin = @admin

    # The original set of fields equivalent to the main entry
    orig_equivs = main_entry.also_equivalent_to.pluck(:id).sort

    fdv = Redcap::DataDictionaries::FieldDatadicVariable.new(check_field)

    manual_equiv = fdv.send(:simple_variable_record_create,
                            fdv.send(:checkbox_choice_overrides,
                                     "#{check_field.name}_test", main_entry))

    expect(manual_equiv.equivalent_to.id).to eq main_entry.id
    expect(main_entry.also_equivalent_to.pluck(:id)).to include manual_equiv.id

    # Add a new checkbox choice
    # A new field entry is added
    check_field.field_choices.select_choices_string_from_def += ' | testnew, Test New'
    dd.send :refresh_variables_records
    expect(check_field.field_choices.choices_plain_text.last).to eq ['testnew', 'Test New']

    new_entry = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id,
                                               variable_name: "#{check_field.name}___testnew").first
    expect(new_entry).not_to be nil
    expect(new_entry.equivalent_to).to eq main_entry

    # The fields now equivalent to the main entry should include the manual item and the testnew entry
    expect(main_entry.also_equivalent_to.pluck(:id).sort).to eq(orig_equivs + [manual_equiv.id, new_entry.id])

    # Change the main field label
    check_field.label += ' - new label'
    check_field.is_required = true
    dd.send :refresh_variables_records
    main_entry.reload

    expect(main_entry.label).to eq check_field.label_plain
    expect(main_entry.is_required).to be true

    # The individual choice fields should reflect the changes
    check_field.checkbox_choice_fields.each do |f|
      v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: f).first
      expect(v.label).to eq check_field.label_plain
      expect(v.is_required).to be true
    end

    # The manual item should be unchanged
    new_manual_equiv = Datadic::Variable.find(manual_equiv.id)
    expect(new_manual_equiv.label).to eq manual_equiv.label

    # Remove a checkbox choice.
    # The field entry should be removed by disabling it.
    new_list = check_field.field_choices.choices
    del_item = new_list.delete_at 1

    check_field.field_choices.select_choices_string_from_def = Redcap::DataDictionaries::FieldChoices.select_choices_string_from(new_list)
    dd.send :refresh_variables_records

    res = Datadic::Variable.where(redcap_data_dictionary_id: dd.id,
                                  variable_name: "#{check_field.name}___#{del_item.first}").first
    expect(res.disabled).to be true
    new_equivs = (orig_equivs + [manual_equiv.id, new_entry.id]).dup
    new_equivs.delete_at 1
    expect(main_entry.also_equivalent_to.active.pluck(:id).sort).to eq new_equivs
  end
end
