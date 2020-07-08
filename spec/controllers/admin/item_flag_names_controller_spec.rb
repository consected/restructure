# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ItemFlagNamesController, type: :controller do
  include ItemFlagNameSupport

  def object_class
    Classification::ItemFlagName
  end

  def item
    @item_flag_name
  end

  def edit_form_admin
    @edit_form_admin = 'admin/common_templates/_form'
  end

  def saved_item_template
    'admin/common_templates/_item'
  end

  before(:context) do
    @path_prefix = '/admin'
    @uses_common_templates = true
  end

  it_behaves_like 'a standard admin controller'
end
