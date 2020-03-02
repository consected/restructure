require 'rails_helper'

SetupHelper.setup_al_player_contact_phones

RSpec.describe AdminHandler, type: :model do

  include ModelSupport

  before :all do
    create_admin
  end

  it "Checks if an admin item is already present" do

    a = Admin::AppType.new(name: 'zeus', label: 'Zeus')
    expect(a.already_taken(:name)).to be true
    expect(a.already_taken(:name, :label)).to be true

    a = Admin::AppType.new(name: 'zeus', label: 'Not Taken')
    expect(a.already_taken(:name)).to be true
    expect(a.already_taken(:name, :label)).to be false

    a = Admin::AppType.new(name: 'not taken', label: 'Not Taken')
    expect(a.already_taken(:name)).to be false
    expect(a.already_taken(:name, :label)).to be false

  end

  it "checks if a general selection item is already present" do
    g = Classification::GeneralSelection.new item_type:'player_contacts_type', name: 'Email', value: 'email', current_admin: @admin
    expect(g.already_taken(:item_type, :value)).to be true

    g = Classification::GeneralSelection.new item_type:'player_contacts_type', name: 'Not Email', value: 'not email', current_admin: @admin
    expect(g.already_taken(:item_type, :value)).to be false

    g.save!
    expect(g.already_taken(:item_type, :value)).to be false

  end

end
