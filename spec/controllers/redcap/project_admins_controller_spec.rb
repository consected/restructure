# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::ProjectAdminsController, type: :controller do
  include Redcap::RedcapSupport

  def object_class
    Redcap::ProjectAdmin
  end

  def item
    @project_admin
  end

  before(:context) do
    @path_prefix = '/redcap'

    setup_redcap_project_admin_configs
  end

  it_behaves_like 'a standard admin controller'
end
