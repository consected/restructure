# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe Redcap::ProjectUsers, type: :model do
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
    dr = Redcap::ProjectUsers.new(rc)

    res = dr.retrieve

    expect(res).to be_a Array
    expect(res.length).to eq 4
    expect(res.first).to be_a Hash
    expect(res.first.keys.first).to eq :username
  end

  it 'validates retrieved records' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    dr = Redcap::ProjectUsers.new(rc)

    dr.retrieve

    expect { dr.validate }.not_to raise_error
  end

  it 'stores retrieved records' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    dr = Redcap::ProjectUsers.new(rc)

    dr.retrieve

    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_usernames.sort).to eq %w[d20 h16 j86 p106].sort
    expect(dr.updated_usernames).to be_empty
    expect(dr.disabled_usernames).to be_empty
  end

  it 'does nothing if the records all match' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    dr = Redcap::ProjectUsers.new(rc)

    dr.retrieve

    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_usernames.sort).to eq %w[d20 h16 j86 p106].sort
    expect(dr.updated_usernames).to be_empty
    expect(dr.disabled_usernames).to be_empty

    dr = Redcap::ProjectUsers.new(rc)
    dr.retrieve

    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_usernames.sort).to be_empty
    expect(dr.updated_usernames).to be_empty
    expect(dr.disabled_usernames).to be_empty
  end

  it 'does updates on records that have changed' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    dr = Redcap::ProjectUsers.new(rc)

    dr.retrieve

    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_usernames.sort).to eq %w[d20 h16 j86 p106].sort
    expect(dr.updated_usernames).to be_empty
    expect(dr.disabled_usernames).to be_empty

    WebMock.reset!
    rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records)

    rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

    stub_request_project_users_updated @project[:server_url], @project[:api_key]

    dr = Redcap::ProjectUsers.new(rc)
    dr.retrieve

    expect { dr.validate }.not_to raise_error
    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_usernames.sort).to be_empty
    expect(dr.updated_usernames.sort).to eq %w[h16 j86].sort
    expect(dr.disabled_usernames).to be_empty
  end

  it 'does disables removed users' do
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin
    dr = Redcap::ProjectUsers.new(rc)

    dr.retrieve

    expect { dr.validate }.not_to raise_error

    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_usernames.sort).to eq %w[d20 h16 j86 p106].sort
    expect(dr.updated_usernames).to be_empty
    expect(dr.disabled_usernames).to be_empty

    WebMock.reset!
    rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records)

    rc.api_client.send :clear_cache, rc.api_client.send(:cache_key, :records, rc.records_request_options)

    stub_request_project_users_deleted @project[:server_url], @project[:api_key]

    dr = Redcap::ProjectUsers.new(rc)
    dr.retrieve

    expect { dr.validate }.not_to raise_error
    dr.store

    expect(dr.errors).to be_empty
    expect(dr.created_usernames.sort).to be_empty
    expect(dr.unchanged_usernames.sort).to eq %w[d20].sort
    expect(dr.updated_usernames).to eq %w[j86]
    expect(dr.disabled_usernames.sort).to eq %w[h16 p106].sort
  end

  # Tests for issue #1260 - requesting removal of a REDCap project user
  # via a background job, allowing the admin UI to trigger the removal
  # from the "REDCap Users" panel of the project admin edit form.
  describe '#request_remove_user' do
    it 'enqueues a job to remove the user from the project' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      dr = Redcap::ProjectUsers.new(rc)

      fake_job = double('job', job_id: 'test-job-id')
      allow(Redcap::RemoveProjectUserJob).to receive(:perform_later).and_return(fake_job)

      dr.request_remove_user('d20')

      expect(Redcap::RemoveProjectUserJob).to have_received(:perform_later).with(rc, 'd20')
    end

    it 'records a job request for the removal action' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      dr = Redcap::ProjectUsers.new(rc)

      fake_job = double('job', job_id: 'test-job-id')
      allow(Redcap::RemoveProjectUserJob).to receive(:perform_later).and_return(fake_job)

      dr.request_remove_user('d20')

      # NOTE: Redcap::ClientRequest has a default_scope limiting to 1000 rows,
      # so #count is capped and unreliable across a large test run - check the
      # specific record created for this project admin instead.
      # NOTE: the username is stored in the result hash, not the action, so
      # that the action remains a fixed, filterable value.
      audit = Redcap::ClientRequest.where(redcap_project_admin: rc).order(created_at: :desc).first
      expect(audit).to be_present
      expect(audit.action).to eq 'remove project user'
      expect(audit.result).to include('requested' => true, 'username' => 'd20')
    end

    it 'does not enqueue a duplicate job if one is already queued' do
      rc = Redcap::ProjectAdmin.active.first
      rc.current_admin = @admin
      dr = Redcap::ProjectUsers.new(rc)

      allow(Redcap::ProjectAdmin).to receive(:existing_jobs).and_return(double(count: 1))
      expect(Redcap::RemoveProjectUserJob).not_to receive(:perform_later)

      dr.request_remove_user('d20')
    end
  end
end
