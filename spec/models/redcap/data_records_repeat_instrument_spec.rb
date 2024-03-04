# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe Redcap::DataRecords, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :all do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first
    @metadata_project = @projects.find { |p| p[:name] == 'metadata' }
    setup_repeat_instrument_fields
  end

  it 'cleanly handles repeat instrument fields in records' do
    setup_repeat_instrument_fields
    rc = @project_admin_metadata
    rc.reload
    rc.current_admin = @admin
    rc.api_key = @metadata_project[:api_key]
    pi = rc.captured_project_info
    expect(pi).to be_a Hash
    expect(pi[:has_repeating_instruments_or_events]).to eq 1

    expect(rc.repeating_instruments?).to be true

    dd = rc.redcap_data_dictionary
    repeat_fields = dd.all_fields_of_type(:repeat)

    # The repeat fields are not in the form, instead are at the top project level
    expect(repeat_fields.keys).to eq []

    @dm_sf = dm = rc.dynamic_storage.dynamic_model.implementation_class
    dm = rc.dynamic_storage.dynamic_model.implementation_class
    expect(dm.attribute_names.include?('varname')).to be true
    expect(dm.attribute_names.include?('redcap_repeat_instrument')).to be true
    expect(dm.attribute_names.include?('redcap_repeat_instance')).to be true

    dr = Redcap::DataRecords.new(rc, dm.name)
    dr.retrieve
    dr.summarize_fields
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids[0..5]).to eq [
      {
        redcap_repeat_instance: '',
        redcap_repeat_instrument: '',
        varname: 'abnormal_eps'
      },
      {
        redcap_repeat_instance: 1,
        redcap_repeat_instrument: 'visitspecific_information',
        varname: 'abnormal_eps'
      },
      {
        redcap_repeat_instance: '',
        redcap_repeat_instrument: '',
        varname: 'birthwt'
      },
      {
        redcap_repeat_instance: 1,
        redcap_repeat_instrument: 'visitspecific_information',
        varname: 'birthwt'
      },
      {
        redcap_repeat_instance: '',
        redcap_repeat_instrument: '',
        varname: 'birthwt_epq'
      },
      {
        redcap_repeat_instance: 1,
        redcap_repeat_instrument: 'visitspecific_information',
        varname: 'birthwt_epq'
      }

    ]
    expect(dr.updated_ids).to be_empty

    expect(@dm_sf.where(varname: 'birthwt').count).to eq 2
    expect(@dm_sf.where(varname: 'birthwt', redcap_repeat_instance: 1).first.redcap_repeat_instrument).to eq 'visitspecific_information'

    dr = Redcap::DataRecords.new(rc, dm.name)
    dr.retrieve
    dr.summarize_fields
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to be_empty
    expect(dr.updated_ids).to be_empty

    # Now add a record by hand and repeat the run to simulate the deletion of redcap record
    newrec = dm.new varname: 'birthwt', redcap_repeat_instrument: 'visitspecific_information', redcap_repeat_instance: '2', current_user: @admin.matching_user
    newrec.force_save!
    newrec.save!

    dr = Redcap::DataRecords.new(rc, dm.name)
    dr.retrieve
    dr.summarize_fields
    expect { dr.validate }.to raise_error(FphsException, 'Redcap::DataRecords retrieved fewer records (8) than expected (9)')
  end

  it 'cleanly deleted repeat instrument fields in records' do
    setup_repeat_instrument_fields
    rc = @project_admin_metadata
    rc.reload
    rc.current_admin = @admin
    rc.api_key = @metadata_project[:api_key]
    rc.data_options.handle_deleted_records = 'disable'
    rc.save!
    rc.reload
    rc.api_key = @metadata_project[:api_key]
    pi = rc.captured_project_info
    c = rc.dynamic_storage.dynamic_model.implementation_class
    # Fake a disabled attribute
    c.attr_accessor :disabled

    c.define_method(:saved_change_to_disabled?) do
      true
    end

    c.define_method(:disabled?) do
      !!disabled
    end

    expect(pi).to be_a Hash
    expect(pi[:has_repeating_instruments_or_events]).to eq 1

    expect(rc.repeating_instruments?).to be true

    dd = rc.redcap_data_dictionary
    repeat_fields = dd.all_fields_of_type(:repeat)

    # The repeat fields are not in the form, instead are at the top project level
    expect(repeat_fields.keys).to eq []

    @dm_sf = dm = rc.dynamic_storage.dynamic_model.implementation_class
    dm = rc.dynamic_storage.dynamic_model.implementation_class
    expect(dm.attribute_names.include?('varname')).to be true
    expect(dm.attribute_names.include?('redcap_repeat_instrument')).to be true
    expect(dm.attribute_names.include?('redcap_repeat_instance')).to be true

    dr = Redcap::DataRecords.new(rc, dm.name)
    dr.retrieve
    dr.summarize_fields
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids[0..5]).to eq [
      {
        redcap_repeat_instance: '',
        redcap_repeat_instrument: '',
        varname: 'abnormal_eps'
      },
      {
        redcap_repeat_instance: 1,
        redcap_repeat_instrument: 'visitspecific_information',
        varname: 'abnormal_eps'
      },
      {
        redcap_repeat_instance: '',
        redcap_repeat_instrument: '',
        varname: 'birthwt'
      },
      {
        redcap_repeat_instance: 1,
        redcap_repeat_instrument: 'visitspecific_information',
        varname: 'birthwt'
      },
      {
        redcap_repeat_instance: '',
        redcap_repeat_instrument: '',
        varname: 'birthwt_epq'
      },
      {
        redcap_repeat_instance: 1,
        redcap_repeat_instrument: 'visitspecific_information',
        varname: 'birthwt_epq'
      }

    ]
    expect(dr.updated_ids).to be_empty

    expect(@dm_sf.where(varname: 'birthwt').count).to eq 2
    expect(@dm_sf.where(varname: 'birthwt', redcap_repeat_instance: 1).first.redcap_repeat_instrument).to eq 'visitspecific_information'

    dr = Redcap::DataRecords.new(rc, dm.name)
    dr.retrieve
    dr.summarize_fields
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to be_empty
    expect(dr.updated_ids).to be_empty

    # Now add a record by hand and repeat the run to simulate the deletion of redcap record
    newrec = dm.new varname: 'birthwt', redcap_repeat_instrument: 'visitspecific_information', redcap_repeat_instance: '2', current_user: @admin.matching_user
    newrec.force_save!
    newrec.save!

    dr = Redcap::DataRecords.new(rc, dm.name)
    dr.retrieve
    dr.summarize_fields
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to be_empty
    expect(dr.updated_ids).to eq []
    expect(dr.disabled_ids).to eq [newrec.varname]
  end

  after :all do
    reset_mocks
  end
end
