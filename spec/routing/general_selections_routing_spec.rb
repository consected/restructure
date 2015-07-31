require "rails_helper"

RSpec.describe GeneralSelectionsController, type: :routing do
  let(:object_name) { 'general_selections' }
  let(:object_path) { '/general_selections'}
  let(:parent_params) { {} }
  it_behaves_like 'a standard admin routing'
end
