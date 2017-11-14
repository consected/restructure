require "rails_helper"

RSpec.describe ScantronsController, type: :routing do
  let(:object_name) { 'scantrons' }
  let(:object_path) { 'masters/2/scantrons'}
  let(:parent_params) { { master_id: '2'} }
  before :all do
    # Handle a strange issue during full test runs
    ExternalIdentifier.routes_reload
  end
  it_behaves_like 'a standard user routing'
end
