# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe Redcap::DataCollectionInstrument, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :example do
    @bad_admin, = create_admin
    @bad_admin.update! disabled: true
    create_admin
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first
    reset_mocks
    Redcap::ProjectUser.update_all(redcap_project_admin_id: nil)
  end

  it 'retrieves records from REDCap immediately' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    res = Redcap::DataCollectionInstrument.retrieve_and_store(rc)

    expect(res).to be_a Array
    expect(res.length).to eq 3
    expect(res.first).to be_a Hash
    expect(res.first.keys.first).to eq :instrument_name
    expect(res.first.keys.last).to eq :instrument_label
  end

  it 'stores retrieved records' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    res = Redcap::DataCollectionInstrument.retrieve_and_store(rc)

    expect(res.map { |r| r[:instrument_name] }.sort).to eq %w[non_survey q2_survey test].sort
  end

  it 'does nothing if the records all match' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    Redcap::DataCollectionInstrument.retrieve_and_store(rc)
    expect(rc.redcap_data_collection_instruments.active.count).to eq 3

    Redcap::DataCollectionInstrument.retrieve_and_store(rc)
    expect(rc.redcap_data_collection_instruments.active.count).to eq 3
  end

  it 'does updates on records that have changed' do
    project_admin = rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    Redcap::DataCollectionInstrument.retrieve_and_store(rc)
    expect(project_admin.redcap_data_collection_instruments.active.order(id: :asc).count).to eq 3

    first = project_admin.redcap_data_collection_instruments.active.order(id: :asc).first
    first_res = first.slice(:name, :label)
    first.update!(label: 'forced update', current_admin: rc.current_admin)

    first = project_admin.redcap_data_collection_instruments.active.order(id: :asc).reload.first
    expect(first.label).to eq 'forced update'

    Redcap::DataCollectionInstrument.retrieve_and_store(rc)
    first = project_admin.redcap_data_collection_instruments.active.order(id: :asc).reload.first
    expect(first.label).to eq first_res[:label]
  end

  it 'disables removed users' do
    project_admin = rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    Redcap::DataCollectionInstrument.retrieve_and_store(rc)
    expect(project_admin.redcap_data_collection_instruments.active.order(id: :asc).count).to eq 3

    project_admin.redcap_data_collection_instruments.create!(name: 'new', label: 'New Record', current_admin: rc.current_admin)
    expect(project_admin.redcap_data_collection_instruments.active.order(id: :asc).reload.count).to eq 4

    Redcap::DataCollectionInstrument.retrieve_and_store(rc)
    expect(project_admin.redcap_data_collection_instruments.active.order(id: :asc).reload.count).to eq 3
    expect(project_admin.redcap_data_collection_instruments.where(name: 'new').first.disabled).to be true
  end
end
