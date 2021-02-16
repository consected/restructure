# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::ProjectAdminsController, type: :controller do
  include MasterSupport
  include Redcap::RedcapSupport
  include Redcap::ProjectAdminSupport

  def object_class
    Redcap::ProjectAdmin
  end

  def item
    @project_admin
  end

  def edit_form_admin
    @edit_form_admin = 'admin/common_templates/_form'
  end

  def saved_item_template
    'admin/common_templates/_item'
  end

  before(:context) do
    @path_prefix = '/redcap'
    @admin, = ControllerMacros.create_admin
    # setup_redcap_project_admin_configs
  end

  it_behaves_like 'a standard admin controller'
end
