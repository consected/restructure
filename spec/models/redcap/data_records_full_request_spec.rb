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
    reset_mocks

    mock_full_requests
    `mkdir -p db/app_migrations/redcap_test; rm -f db/app_migrations/redcap_test/*test_full_*.rb`

    tn = "redcap_test.test_full_rc#{rand 100_000_000_000_000}_recs"
    @project_admin = rc = Redcap::ProjectAdmin.create! name: @project[:name], server_url: server_url('full'), api_key: @project[:api_key], study: 'Q3',
                                                       current_admin: @admin, dynamic_model_table: tn

    rc.force_refresh = true
    rc.update!(updated_at: DateTime.now)
    @dm = rc.dynamic_storage.dynamic_model

    expect(rc.dynamic_model_ready?).to be_truthy
    @dmcn = @dm.implementation_class.name

    tn = "redcap_test.test_full_sf_rc#{rand 100_000_000_000_000}_recs"
    @project_admin_sf = rc_sf = Redcap::ProjectAdmin.create! name: @project[:name], server_url: server_url('full'), api_key: @project[:api_key], study: 'Q4',
                                                             current_admin: @admin, dynamic_model_table: tn,
                                                             use_hash_config: {
                                                               records_request_options: { exportSurveyFields: true }
                                                             }

    rc_sf.force_refresh = true
    rc_sf.update!(updated_at: DateTime.now)
    @dm_sf = rc_sf.dynamic_storage.dynamic_model
    expect(rc_sf.dynamic_model_ready?).to be_truthy
    @dmcn_sf = @dm_sf.implementation_class.name
  end

  it 'cleanly handles full records' do
    rc = @project_admin
    rc.current_admin = @admin
    mock_full_requests

    dr = Redcap::DataRecords.new(rc, @dmcn)
    dr.retrieve
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to eq (1..33).map(&:to_s).sort
    expect(dr.updated_ids).to be_empty

    dr = Redcap::DataRecords.new(rc, @dmcn)
    dr.retrieve
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to be_empty
    expect(dr.updated_ids).to be_empty
  end

  it 'handles variable sections' do
    rc = @project_admin
    rc.current_admin = @admin
    mock_full_requests

    dd = rc.redcap_data_dictionary
    # dd.forms[:q2_survey].fields[:introduction]

    v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: :introduction).first
    expect(v).not_to be_nil
    expect(v.variable_name).to eq 'introduction'
    expect(v.variable_type).to eq 'fixed caption'
    expect(v.title).to eq ''
    expect(v.position).to eq 1
    expect(v.section_id).to be_nil
    expect(v.sub_section_id).to be_nil

    v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: :cosent_text).first
    expect(v).not_to be_nil
    expect(v.variable_name).to eq 'cosent_text'
    expect(v.variable_type).to eq 'fixed caption'
    expect(v.title).to eq 'Permission to Take Part in a Human Research Study'
    expect(v.position).to eq 2
    expect(v.section_id).to be_nil
    expect(v.sub_section_id).to be_nil

    v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: :demog_outline).first
    expect(v).not_to be_nil
    expect(v.variable_name).to eq 'demog_outline'
    expect(v.variable_type).to eq 'fixed caption'
    expect(v.title).to eq 'Demographic Information and Playing History'
    expect(v.position).to eq 5
    expect(v.section_id).to be_nil
    expect(v.sub_section_id).to be_nil

    inst = Redcap::DataDictionaries::FieldDatadicVariable.find_by_identifiers(source_name: v.source_name,
                                                                              source_type: :redcap,
                                                                              form_name: v.form_name,
                                                                              variable_name: 'demog_outline',
                                                                              owner: v.redcap_data_dictionary_id).first

    expect(inst.position).to eq 5
    expect(inst.id).to eq v.id

    v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: :dob).first
    expect(v).not_to be_nil
    expect(v.variable_name).to eq 'dob'
    expect(v.variable_type).to eq 'date'
    expect(v.position).to eq 6
    expect(v.section_id).to eq inst.id
    expect(v.sub_section_id).to be_nil

    v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: :current_weight).first
    expect(v).not_to be_nil
    expect(v.variable_name).to eq 'current_weight'
    expect(v.variable_type).to eq 'numeric'
    expect(v.position).to eq 7
    expect(v.section_id).to eq inst.id
    expect(v.sub_section_id).to be_nil

    v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: :famedu_text).first
    expect(v).not_to be_nil
    expect(v.variable_name).to eq 'famedu_text'
    expect(v.variable_type).to eq 'fixed caption'
    expect(v.position).to eq 26
    expect(v.section_id).to eq nil
    expect(v.sub_section_id).to be_nil

    inst = Redcap::DataDictionaries::FieldDatadicVariable.find_by_identifiers(source_name: v.source_name,
                                                                              source_type: :redcap,
                                                                              form_name: v.form_name,
                                                                              variable_name: 'famedu_text',
                                                                              owner: v.redcap_data_dictionary_id).first

    expect(inst.position).to eq 26

    v = Datadic::Variable.active.where(redcap_data_dictionary_id: dd.id, variable_name: :edu_player).first
    expect(v).not_to be_nil
    expect(v.variable_name).to eq 'edu_player'
    expect(v.variable_type).to eq 'categorical'
    expect(v.position).to eq 27
    expect(v.section_id).to eq inst.id
    expect(v.sub_section_id).to be_nil
  end

  it 'cleanly handles full records with survey fields' do
    rc = @project_admin_sf
    rc.current_admin = @admin
    mock_full_requests

    dr = Redcap::DataRecords.new(rc, @dmcn_sf)
    dr.retrieve
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to eq (1..33).map(&:to_s).sort
    expect(dr.updated_ids).to be_empty

    expect(@dm_sf.implementation_class.first.q2_survey_timestamp).to be_nil

    dr = Redcap::DataRecords.new(rc, @dmcn_sf)
    dr.retrieve
    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_ids.sort).to be_empty
    expect(dr.updated_ids).to be_empty
  end

  after :all do
    reset_mocks
  end
end
