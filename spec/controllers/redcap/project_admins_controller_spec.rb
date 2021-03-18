# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Redcap::ProjectAdminsController, type: :controller do
  include UserSupport

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
    create_admin_matching_user
  end

  before(:example) do
    create_admin_matching_user
  end

  it_behaves_like 'a standard admin controller'
end
