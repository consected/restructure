require "rails_helper"

RSpec.describe ProtocolsController, type: :routing do
  let(:object_name) { 'protocols' }
  let(:object_path) { '/protocols'}
  let(:parent_params) { {} }
  it_behaves_like 'a standard admin routing'
end
