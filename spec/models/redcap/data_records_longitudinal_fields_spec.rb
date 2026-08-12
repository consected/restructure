# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe Redcap::DataRecords, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :all do
    # SetupHelper.get_webmock_responses
    change_setting('AllowDynamicMigrations', true)
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs # (only_project: 'longitudinal')
    @project = @projects.first
    @metadata_project = @projects.find { |p| p[:name] == 'longitudinal' }
    setup_longitudinal_fields
  end

  it 'cleanly handles longitudinal fields in records' do
    setup_longitudinal_fields
    rc = @project_admin_metadata
    rc.reload
    rc.current_admin = @admin
    rc.api_key = @metadata_project[:api_key]
    pi = rc.captured_project_info
    expect(pi).to be_a Hash
    expect(pi[:is_longitudinal]).to eq 1

    expect(rc.is_longitudinal?).to be true

    dd = rc.redcap_data_dictionary
    longitudinal_fields = dd.all_fields_of_type(:event_name)

    # The longitudinal fields are not in the form, instead are at the top project level
    expect(longitudinal_fields.keys).to eq []

    @dm_sf = dm = rc.dynamic_storage.dynamic_model.implementation_class
    dm = rc.dynamic_storage.dynamic_model.implementation_class
    expect(dm.attribute_names.include?('text1')).to be true
    expect(dm.attribute_names.include?('study_id')).to be true
    expect(dm.attribute_names.include?('test_name')).to be true
    expect(dm.attribute_names.include?('email')).to be true
    expect(dm.attribute_names.include?('redcap_event_name')).to be true

    dr = Redcap::DataRecords.new(rc, dm.name)
    dr.retrieve
    dr.summarize_fields
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids[0..5]).to eq [
      {
        record_id: '31',
        redcap_event_name: 'event_1_arm_1'
      },
      {
        record_id: '31',
        redcap_event_name: 'event_2_arm_1'
      },
      {
        record_id: '32',
        redcap_event_name: 'event_1_arm_2'
      },
      {
        record_id: '32',
        redcap_event_name: 'event_2_arm_2'
      },
      {
        record_id: '32',
        redcap_event_name: 'event_3_arm_2'
      }
    ]
    expect(dr.updated_ids).to be_empty

    expect(@dm_sf.where(redcap_event_name: 'event_3_arm_2').count).to eq 1
    expect(@dm_sf.where(redcap_event_name: 'event_3_arm_2').first.test_name).to eq 'a2 visit e3'

    dr = Redcap::DataRecords.new(rc, dm.name)
    dr.retrieve
    dr.summarize_fields
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to be_empty
    expect(dr.updated_ids).to be_empty

    # Now add a record by hand and repeat the run to simulate the deletion of redcap record
    newrec = dm.new test_name: 'birthwt', redcap_event_name: 'event_2_arm_2', current_user: @admin.matching_user
    newrec.force_save!
    newrec.save!

    dr = Redcap::DataRecords.new(rc, dm.name)
    dr.retrieve
    dr.summarize_fields
    expect { dr.validate }.to raise_error(FphsException, 'Redcap::DataRecords retrieved fewer records (5) than expected (6)')
  end

  it 'cleanly deleted longitudinal fields records' do
    setup_longitudinal_fields
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
    expect(pi[:is_longitudinal]).to eq 1

    expect(rc.is_longitudinal?).to be true

    dd = rc.redcap_data_dictionary
    longitudinal_fields = dd.all_fields_of_type(:event_type)

    # The longitudinal fields are not in the form, instead are at the top project level
    expect(longitudinal_fields.keys).to eq []

    @dm_sf = dm = rc.dynamic_storage.dynamic_model.implementation_class
    dm = rc.dynamic_storage.dynamic_model.implementation_class
    expect(dm.attribute_names.include?('text1')).to be true
    expect(dm.attribute_names.include?('study_id')).to be true
    expect(dm.attribute_names.include?('test_name')).to be true
    expect(dm.attribute_names.include?('email')).to be true
    expect(dm.attribute_names.include?('redcap_event_name')).to be true

    dr = Redcap::DataRecords.new(rc, dm.name)
    dr.retrieve
    dr.summarize_fields
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids[0..5]).to eq [
      {
        record_id: '31',
        redcap_event_name: 'event_1_arm_1'
      },
      {
        record_id: '31',
        redcap_event_name: 'event_2_arm_1'
      },
      {
        record_id: '32',
        redcap_event_name: 'event_1_arm_2'
      },
      {
        record_id: '32',
        redcap_event_name: 'event_2_arm_2'
      },
      {
        record_id: '32',
        redcap_event_name: 'event_3_arm_2'
      }
    ]
    expect(dr.updated_ids).to be_empty

    expect(@dm_sf.where(redcap_event_name: 'event_1_arm_2').count).to eq 1

    dr = Redcap::DataRecords.new(rc, dm.name)
    dr.retrieve
    dr.summarize_fields
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to be_empty
    expect(dr.updated_ids).to be_empty

    # Now add a record by hand and repeat the run to simulate the deletion of redcap record
    newrec = dm.new test_name: 'birthwt', redcap_event_name: 'event_1_arm_2', current_user: @admin.matching_user
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
    expect(dr.disabled_ids).to eq [newrec.record_id]
  end

  after :all do
    reset_mocks
  end
end
