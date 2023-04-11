require "rails_helper"

RSpec.describe Admin::ExternalIdentifiersController, type: :routing do
  let(:object_name) { 'external_identifiers' }
  let(:object_path) { '/admin/external_identifiers' }
  let(:parent_params) { {} }
  it_behaves_like 'a standard admin routing'
end
