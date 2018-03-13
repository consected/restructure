require 'rails_helper'

# Test the user action log functionality by exercising the AddressesController

RSpec.describe AddressesController, type: :controller do

  include AddressSupport

  def item
    @address
  end

  def object_class
    Address
  end

  def edit_form_prefix
    @edit_form_prefix = "common_templates"
  end


  before_each_login_user

  it "records an action for a controller" do

    setup_access :addresses
    setup_access :trackers


    create_items

    t0 = DateTime.now
    get :show, id: @address.id, master_id: @master.id

    res = UserActionLog.order(id: :desc).limit(1).first
    expect(res).to be_a UserActionLog
    expect(res.master_id).to eq @master.id
    expect(res.item_type).to eq 'addresses'
    expect(res.item_id).to eq @address.id
    expect(res.user_id).to eq @user.id
    expect(res.app_type_id).to eq @user.app_type_id
    expect(res.created_at).to be_between(t0, DateTime.now)
    expect(res.action).to eq 'show'







  end

end
