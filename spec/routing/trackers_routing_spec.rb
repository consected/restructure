require "rails_helper"

RSpec.describe TrackersController, type: :routing do
 
  let(:object_name) { 'trackers' }
  let(:object_path) { 'masters/2/trackers'}
  let(:parent_params) { { master_id: '2'} }
  it_behaves_like 'a standard user routing'

 
end
