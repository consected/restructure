require "rails_helper"

RSpec.describe PlayerContactsController, type: :routing do
  let(:object_name) { 'player_contacts' }
  let(:object_path) { 'masters/2/player_contacts'}
  
  it_behaves_like 'a standard user routing'
end
