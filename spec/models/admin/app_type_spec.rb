# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::AppType, type: :model do
  include ModelSupport

  it 'creates a new application type' do
    create_admin
    app = Admin::AppType.create!(name: 'test', label: 'Test App', current_admin: @admin)
    expect(app).to be_a Admin::AppType

    template_uac = Admin::UserAccessControl.last
    expect(template_uac.app_type_id).to eq app.id
    expect(template_uac.role_name).to eq '_app_'
  end

  it 'allows a user access to an app type' do
    create_admin
    create_user

    # Create an app
    app = Admin::AppType.create!(name: 'test', label: 'Test App', current_admin: @admin)

    # Initially the user should not have access to the new app
    allapps = Admin::AppType.all_available_to @user
    expect(allapps).not_to include app

    allapp_ids = Admin::AppType.all_ids_available_to @user
    expect(allapp_ids).not_to include app.id

    # Create baseline access to the app
    ac = Admin::UserAccessControl.create! app_type_id: app.id, access: :read, resource_type: :general, resource_name: :app_type, current_admin: @admin

    # The user's available apps should include it
    allapps = Admin::AppType.all_available_to @user
    expect(allapps).to include app

    allapp_ids = Admin::AppType.all_ids_available_to @user
    expect(allapp_ids).to include app.id

    # Set default access to nil
    ac.access = nil
    ac.save!

    # The user should not have the app available
    allapps = Admin::AppType.all_available_to @user
    expect(allapps).not_to include app

    allapp_ids = Admin::AppType.all_ids_available_to @user
    expect(allapp_ids).not_to include app.id

    # Add a user specific control for the user
    uac = Admin::UserAccessControl.create! app_type_id: app.id, access: :read, resource_type: :general, resource_name: :app_type, current_admin: @admin, user_id: @user.id

    # The user should now be able to access it
    allapps = Admin::AppType.all_available_to @user
    expect(allapps).to include app

    allapp_ids = Admin::AppType.all_ids_available_to @user
    expect(allapp_ids).to include app.id

    # Set the user to not have access even if we set default access to allow
    ac.access = :read
    ac.save!

    uac.access = nil
    uac.save!

    # The user should not have the app available
    allapps = Admin::AppType.all_available_to @user
    expect(allapps).not_to include app

    allapp_ids = Admin::AppType.all_ids_available_to @user
    expect(allapp_ids).not_to include app.id
  end
end
