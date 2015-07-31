require "rails_helper"

RSpec.describe AddressesController, type: :routing do
  let(:object_name) { 'addresses' }
  let(:object_path) { 'masters/2/addresses'}
  let(:parent_params) { {master_id: '2'} }
  it_behaves_like 'a standard user routing'
end
