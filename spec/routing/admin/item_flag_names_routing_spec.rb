require "rails_helper"

RSpec.describe Admin::ItemFlagNamesController, type: :routing do
  let(:object_name) { 'item_flag_names' }
  let(:object_path) { '/admin/item_flag_names'}
  let(:parent_params) { {} }
  it_behaves_like 'a standard admin routing'
end
