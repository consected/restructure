# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Classification::GeneralSelection, type: :model do
  include ModelSupport
  include GeneralSelectionSupport

  before :example do
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
