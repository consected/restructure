# frozen_string_literal: true

require 'rails_helper'

# Tests for issue #1260 - Redcap::RemoveProjectUserJob calls the REDCap API to
# remove a user's access from a project, then refreshes the locally stored
# project user list so that the "REDCap Users" admin panel reflects the
# removal once the background job completes.
RSpec.describe Redcap::RemoveProjectUserJob, type: :job do
  include ModelSupport
  include Redcap::RedcapSupport
  include Redcap::ProjectAdminSupport

  before :example do
    create_admin
    create_admin_matching_user
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first
    Redcap::ProjectUser.update_all(redcap_project_admin_id: nil)
  end

  # Retrieve and store the initial full list of project users, so that
  # locally persisted Redcap::ProjectUser records exist to be disabled later.
  def project_admin_with_users
    rc = Redcap::ProjectAdmin.active.first
    rc.current_admin = @admin

    dr = Redcap::ProjectUsers.new(rc)
    dr.retrieve
    dr.validate
    dr.store

    rc
  end

  it 'removes the user from REDCap and refreshes the stored user list' do
    rc = project_admin_with_users
    # NOTE: scope by redcap_project_admin - other REDCap projects set up by
    # setup_redcap_project_admin_configs share the same demo usernames.
    expect(Redcap::ProjectUser.find_by(redcap_project_admin: rc, username: 'h16').disabled).to be_falsey

    WebMock.reset!
    stub_request_remove_project_user @project[:server_url], @project[:api_key], username: 'h16'
    stub_request_project_users_deleted @project[:server_url], @project[:api_key]

    described_class.new.perform(rc, 'h16')

    audit = Redcap::ClientRequest.where(action: 'user').order(created_at: :desc)
                                 .find { |cr| cr.result['api_action'] == 'delete' }
    expect(audit).to be_present

    expect(Redcap::ProjectUser.find_by(redcap_project_admin: rc, username: 'h16').disabled).to be true
  end

  it 'records a failure and re-raises when the REDCap API call fails' do
    rc = project_admin_with_users

    WebMock.reset!
    stub_request(:post, @project[:server_url]).to_return(status: 500, body: '', headers: {})

    expect do
      described_class.new.perform(rc, 'h16')
    end.to raise_error(StandardError)

    expect(rc.reload.status).to eq Redcap::ProjectAdmin::Statuses[:request_failed]
  end
end
