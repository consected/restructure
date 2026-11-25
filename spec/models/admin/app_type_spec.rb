# frozen_string_literal: true

# Purpose: Verify app type configuration notices include errors from associated reports.

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

  it 'includes invalid options from associated reports in configuration notices' do
    create_admin
    app_type = Admin::AppType.create!(
      name: "report notice app #{SecureRandom.hex(4)}",
      label: 'Report Notice App',
      current_admin: @admin
    )
    report = Report.create!(
      current_admin: @admin,
      name: "Report with invalid option #{SecureRandom.hex(4)}",
      item_type: 'report_notice',
      sql: 'select 1 as result_value',
      search_attrs: '',
      options: "view_options:\n  bad_attr: 1",
      report_type: 'report',
      disabled: false
    )
    Admin::UserAccessControl.create!(
      app_type:,
      access: :read,
      resource_type: :report,
      resource_name: report.alt_resource_name,
      current_admin: @admin
    )

    notices = app_type.check_option_configs

    expect(notices.pluck(:message).join).to include('bad_attr')
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
