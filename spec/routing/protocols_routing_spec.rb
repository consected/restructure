require "rails_helper"

RSpec.describe Admin::ProtocolsController, type: :routing do
  let(:object_name) { 'protocols' }
  let(:object_path) { '/admin/protocols'}
  let(:parent_params) { {} }
  it_behaves_like 'a standard admin routing'
end
