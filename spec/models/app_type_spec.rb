require 'rails_helper'

RSpec.describe AppType, type: :model do

  include ModelSupport

  it "creates a new application type" do

    create_admin
    res = AppType.create!(name: 'test', label:'Test App', current_admin: @admin)
    expect(res).to be_a AppType

  end

  it "allows a user access to an app type" do
    create_admin
    create_user

    # Create an app
    res = AppType.create!(name: 'test', label:'Test App', current_admin: @admin)

    # Initially the user should not have access to the new app
    allapps = AppType.all_available_to @user
    expect(allapps).not_to include res


    # Create baseline access to the app
    ac = UserAccessControl.create! app_type_id: res.id, access: :read, resource_type: :general, resource_name: :app_type, current_admin: @admin

    # The user's available apps should include it
    allapps = AppType.all_available_to @user
    expect(allapps).to include res

    # Set default access to nil
    ac.access = nil
    ac.save!

    # The user should not have the app available
    allapps = AppType.all_available_to @user
    expect(allapps).not_to include res


    # Add a user specific control for the user
    uac = UserAccessControl.create! app_type_id: res.id, access: :read, resource_type: :general, resource_name: :app_type, current_admin: @admin, user_id: @user.id

    # The user should now be able to access it
    allapps = AppType.all_available_to @user
    expect(allapps).to include res


    # Set the user to not have access even if we set default access to allow
    ac.access = :read
    ac.save!

    uac.access = nil
    uac.save!

    # The user should not have the app available
    allapps = AppType.all_available_to @user
    expect(allapps).not_to include res


  end

end
