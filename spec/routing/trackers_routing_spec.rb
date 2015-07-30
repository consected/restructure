require "rails_helper"

RSpec.describe TrackersController, type: :routing do
  describe "routing" do

  let(:object_name) { 'trackers' }
  let(:object_path) { 'masters/2/trackers'}
  
  it_behaves_like 'a standard user routing'

  end
end
