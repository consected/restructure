# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::ClientRequest, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :example do
    create_admin
    @projects = setup_redcap_project_admin_configs
  end

  it 'saves a record for the action' do
    name = @projects.first[:name]

    num = Redcap::ClientRequest.count

    rc = Redcap::ProjectAdmin.find_by_name(name)
    rc.current_admin = @admin
    expect(rc).to be_a Redcap::ProjectAdmin

    rc.project_client.project

    expect(Redcap::ClientRequest.count).to be > num
    expect(Redcap::ClientRequest.last.action).to eq 'project'
  end
end
