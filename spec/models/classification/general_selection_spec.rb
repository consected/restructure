# frozen_string_literal: true

require 'rails_helper'

SetupHelper.setup_test_app

RSpec.describe Classification::GeneralSelection, type: :model do
  include ModelSupport
  include GeneralSelectionSupport

  before :each do
    seed_database
    create_admin
    create_user
    
    create_master
    create_items :list_valid_attribs
  end

  it 'gets active general selection configurations' do
    expect(@list.length).to eq 10

    l = Classification::GeneralSelection.active.length
    expect(l).to be > 10

    res = Classification::GeneralSelection.selector_with_config_overrides
    expect(res.length).to be >= l
  end

  it 'overrides general selection configurations with dynamic model alt_options' do
    config0 = Classification::GeneralSelection.selector_with_config_overrides

    ::ActivityLog.define_models
    @activity_log = al = ActivityLog.enabled.first

    al.extra_log_types = <<EOF
    step_1:
      label: Step 1
      fields:
        - select_call_direction
        - select_who

      field_options:
        select_call_direction:
          edit_as:
            alt_options:
              This is one: one
              This is two: two
              This is nine: nine

    step_2:
      label: Step 2
      fields:
        - select_call_direction
        - extra_text
EOF

    al.current_admin = @admin
    al.save!

    dm = DynamicModel.active_model_configurations.first.implementation_class

    config1 = Classification::GeneralSelection.selector_with_config_overrides item_type: dm.new.item_type
    expect(config0.length).not_to eq config1.length

    config2 = Classification::GeneralSelection.selector_with_config_overrides extra_log_type: 'step_1', item_type: al.item_type
    expect(config2.length).not_to eq config1.length
  end

  it 'prevents duplicate entries with the same value in an item type' do
    g = Classification::GeneralSelection.new item_type: 'player_contacts_type', name: 'Not Email', value: 'not email', current_admin: @admin
    expect(g.already_taken(:item_type, :value)).to be false

    expect(g.save).to be true

    g = Classification::GeneralSelection.new item_type: 'player_contacts_type', name: 'Email', value: 'email', current_admin: @admin
    expect(g.already_taken(:item_type, :value)).to be true

    expect(g.save).to be false
    expect(g.errors.keys).to include :duplicated
  end
end
