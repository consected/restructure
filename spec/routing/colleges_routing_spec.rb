require "rails_helper"

RSpec.describe CollegesController, type: :routing do
  let(:object_name) { 'colleges' }
  let(:object_path) { '/colleges'}
  let(:parent_params) { {} }
  it_behaves_like 'a standard admin routing'
end
