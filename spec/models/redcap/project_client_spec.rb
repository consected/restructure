# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::ProjectClient, type: :model do
  include ModelSupport
  include Redcap::RedcapSupport

  before :example do
    create_admin
    @projects = setup_redcap_project_admin_configs
  end

  it 'connects and gets project info' do
    name = @projects.first[:name]

    rc = Redcap::ProjectAdmin.find_by_name(name)
    expect(rc).to be_a Redcap::ProjectAdmin

    rc.current_admin = @admin
    c = Redcap::ProjectClient.new(rc)
    expect(c).to be_a Redcap::ProjectClient
    expect(c.api_key).to eq rc.api_key
    expect(c.server_url).to eq rc.server_url
    expect(c.name).to eq rc.name

    expect(c.redcap).to be_a Redcap::Client

    m = c.project
    expect(m).to be_a Hash
    expect(m[:project_title]).to eq name
  end

  it 'requires a ProjectAdmin#current_admin to be set' do
    name = @projects.first[:name]

    rc = Redcap::ProjectAdmin.find_by_name(name)
    expect(rc).to be_a Redcap::ProjectAdmin

    expect do
      rc.project_client.metadata
    end.to raise_error(FphsException, 'Initialization with current_admin blank is not valid')
  end

  it 'connects and gets project data dictionary' do
    name = @projects.first[:name]

    rc = Redcap::ProjectAdmin.find_by_name(name)
    rc.current_admin = @admin
    expect(rc).to be_a Redcap::ProjectAdmin

    m = rc.project_client.metadata
    expect(m).to be_a Array
    expect(m).to be_present
  end
end
