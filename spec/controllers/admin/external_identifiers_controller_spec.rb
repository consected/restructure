# frozen_string_literal: true

require 'rails_helper'

# Tests for issue #1066:
# - Show resolved definition versioning in external identifier admin details
RSpec.describe Admin::ExternalIdentifiersController, type: :controller do
  include MasterSupport
  include ExternalIdentifierSupport

  render_views

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

  describe 'GET #edit issue #1066 details display' do
    it 'shows current version when current-definition mode is resolved' do
      ext = ExternalIdentifier.active.first
      expect(ext).to be_present

      allow_any_instance_of(ExternalIdentifier).to receive(:uses_current_definition_version?).and_return(true)

      get :edit, params: { id: ext.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector('.def-version-resolution', text: /current version/i)
    end

    it 'shows version at record creation when definition-time versioning is resolved' do
      ext = ExternalIdentifier.active.first
      expect(ext).to be_present

      allow_any_instance_of(ExternalIdentifier).to receive(:uses_current_definition_version?).and_return(false)

      get :edit, params: { id: ext.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to have_selector('.def-version-resolution', text: /record creation/i)
    end
  end
end
