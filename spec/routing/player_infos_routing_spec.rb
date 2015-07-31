require "rails_helper"

RSpec.describe PlayerInfosController, type: :routing do
  let(:object_name) { 'player_infos' }
  let(:object_path) { 'masters/2/player_infos'}
  let(:parent_params) { { master_id: '2'} }
  it_behaves_like 'a standard user routing'
end
