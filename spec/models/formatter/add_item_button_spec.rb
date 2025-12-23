require 'rails_helper'

RSpec.describe Formatter::AddItemButton, type: :model do
  include ModelSupport
  include PlayerContactSupport
  include TestFieldsDmSupport

  before(:all) do
    create_user
    create_master
    setup_fields_dm
  end

  it 'generates valid add item button markup' do
    master_id = 42
    resource_name = 'dynamic_model__test_with_id_recs'
    html = Formatter::AddItemButton.markup(resource_name, master_id)

    expect(html).to include("href=\"/masters/#{master_id}/dynamic_model/test_with_id_recs/new\"")
    expect(html).to include("data-target=\"#dynamic-model--test-with-id-recs-#{master_id}-\"")
    expect(html).to include("data-model-name=\"#{resource_name}\"")
    expect(html).to include("data-subscription=\"dynamic-model--test-with-id-rec-edit-form-#{master_id}-\"")
  end
end
