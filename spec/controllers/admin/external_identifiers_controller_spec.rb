# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::ExternalIdentifiersController, type: :controller do
  include MasterSupport
  include ExternalIdentifierSupport

  def object_class
    ExternalIdentifier
  end

  def item
    @external_identifier
  end

  def edit_form_admin
    @edit_form_admin = 'admin/common_templates/_form'
  end

  before(:context) do
    @path_prefix = '/admin'
  end

  before_each_login_admin

  before :each do
    r = 'test7'
    @implementation_table_name = "test_external_#{r}_identifiers"
    @implementation_attr_name = "test_#{r}_id"
    disable_existing_records nil, external_id_attribute: @implementation_attr_name, current_admin: @admin
  end

  it_behaves_like 'a standard admin controller'

  it 'returns an error when the table does not exist' do
    r = '7'
    inv = {
      name: 'table_doesnt_exist',
      label: "test id #{r}",
      external_id_attribute: "test_#{r}_id",
      min_id: 1,
      max_id: 99_999_999,
      disabled: false
    }
    put :create, params: { object_symbol => inv }
    expect(assigns(object_symbol).errors.empty?).not_to be true
  end
end
