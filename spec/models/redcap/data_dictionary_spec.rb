# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::DataDictionary, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :all do
    create_admin
    setup_redcap_project_admin_configs
    setup_repeat_instrument_fields
  end

  before :example do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first
    @metadata_project = @projects.find { |p| p[:name] == 'metadata' }
  end

  it 'stores the data dictionary metadata for future reference' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    expect(rc.redcap_data_dictionary.captured_metadata).to eq rc.api_client.metadata
  end

  it 'produces a list of all fields from all forms' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    dd = rc.redcap_data_dictionary

    count_fields = 0
    dd.forms.each do |_k, form|
      count_fields += form.fields.length
    end

    expect(dd.all_fields).to be_a Hash
    expect(dd.all_fields.length).to eq count_fields

    expect(dd.record_id_field).to eq :record_id
  end

  it 'gets a full list of file fields' do
    setup_file_fields
    rc = @project_admin
    rc.current_admin = @admin

    dd = rc.redcap_data_dictionary
    file_fields = dd.all_fields_of_type(:file)

    expect(file_fields.keys).to eq %i[file1 signature]
    v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: :file1).first
    expect(v).not_to be_nil
    expect(v.variable_name).to eq 'file1'
    expect(v.variable_type).to eq 'file'
  end

  it 'gets a full list of fields when there are repeating instruments' do
    setup_repeat_instrument_fields
    rc = @project_admin_metadata
    rc.reload
    rc.current_admin = @admin
    pi = rc.captured_project_info
    expect(pi).to be_a Hash
    expect(pi[:has_repeating_instruments_or_events]).to eq 1

    expect(rc.repeating_instruments?).to be true

    dd = rc.redcap_data_dictionary
    repeat_fields = dd.all_fields_of_type(:repeat)
    expect(dd.record_id_field).to eq :varname
    expect(dd.record_id_extra_fields).to eq %i[redcap_repeat_instrument redcap_repeat_instance]

    # The repeat fields are not in the form, instead are at the top project level
    expect(repeat_fields.keys).to eq []

    dm = rc.dynamic_storage.dynamic_model.implementation_class
    expect(dm.attribute_names.include?('varname')).to be true
    expect(dm.attribute_names.include?('redcap_repeat_instrument')).to be true
    expect(dm.attribute_names.include?('redcap_repeat_instance')).to be true
  end
end
