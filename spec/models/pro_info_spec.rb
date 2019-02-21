require 'rails_helper'

RSpec.describe ProInfo, type: :model do
  include ModelSupport

  before(:each) do
    seed_database
    create_user
    @master = Master.new
    @master.current_user = @user
    @master.save!
    Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :create, resource_type: :table, resource_name: :pro_infos, current_admin: @admin, user: @user

    @pro_info = @master.pro_infos.build first_name: 'phil', last_name: 'good', middle_name: 'andrew', nick_name: 'mitch'

    @pro_info.save!

  end

  it "should create a pro info for testing" do

    expect(@pro_info).to be_a ProInfo
    expect(@pro_info.id).to_not be nil
  end

  it "should prevent changes" do
    res = @pro_info.update first_name: "charles"

    expect(res).to be false

    @pro_info.reload

    expect(@pro_info.first_name).to eq 'phil'

  end

  it "should allow updates only for special administrative changes" do
    res = @pro_info.update first_name: "charles", enable_updates: true
    expect(res).to be true

    @pro_info.reload

    expect(@pro_info.first_name).to eq 'charles'

  end

end
