require "rails_helper"

RSpec.describe ProInfosController, type: :routing do
  let(:object_name) { 'pro_infos' }
  let(:object_path) { 'masters/2/pro_infos'}
  
  it_behaves_like 'a standard user routing'
end
