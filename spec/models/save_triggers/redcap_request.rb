require 'rails_helper'

RSpec.describe SaveTriggers::RedcapRequest, type: :model do
  include ModelSupport
  include ActivityLogSupport

  include Redcap::RedcapSupport

  before :example do
    create_admin
    @projects = setup_redcap_project_admin_configs
    @project = @projects.first
  end

  before :example do
  end
end
