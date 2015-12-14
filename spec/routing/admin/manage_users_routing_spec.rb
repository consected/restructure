require "rails_helper"

RSpec.describe Admin::ManageUsersController, type: :routing do
    
  let(:object_name) { 'manage_users' }
  let(:object_path) { '/admin/manage_users'}
  let(:parent_params) { {} }
  it_behaves_like 'a standard admin routing'
end
