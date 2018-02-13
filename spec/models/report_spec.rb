require 'rails_helper'

RSpec.describe Report, type: :model do
  include ModelSupport

  it "allows a user to see certain reports, based on access controls" do

    create_admin
    create_user
    res = Report.active.searchable.for_user(@user)
    expect(res.length).to eq 0

    first_rep = Report.active.searchable.first
    expect(first_rep).to be_a Report
    UserAccessControl.create! app_type: @user.app_type, access: :read, resource_type: :report, resource_name: first_rep.name, current_admin: @admin

    res = Report.active.searchable.for_user(@user)
    expect(res.length).to eq 1
    expect(res.first).to eq first_rep


    UserAccessControl.create! app_type: @user.app_type, user: @user, access: nil, resource_type: :report, resource_name: first_rep.name, current_admin: @admin
    res = Report.active.searchable.for_user(@user)
    expect(res.length).to eq 0



  end

end
