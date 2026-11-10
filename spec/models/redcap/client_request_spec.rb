# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::ClientRequest, type: :model do
  include_context 'with redcap project admins'

  it 'saves a record for the action' do
    name = @projects.first[:name]

    num = Redcap::ClientRequest.unscoped.count

    rc = Redcap::ProjectAdmin.active.find_by_name(name)
    rc.current_admin = @admin
    expect(rc).to be_a Redcap::ProjectAdmin

    rc.api_client.project

    expect(Redcap::ClientRequest.unscoped.count).to be > num
    project_request = Redcap::ClientRequest.unscoped.where(action: 'project').order(id: :desc).first
    expect(project_request).to be_present
    expect(project_request.action).to eq 'project'
  end
end
