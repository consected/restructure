# frozen_string_literal: true

require 'rails_helper'

# Verifies that a user can view and update their preferences from the profile page.
# The default page layout and user access control mirror the user-preferences seed.
describe 'user profile preferences panel', js: true, driver: $browser_driver do
  include FeatureSupport
  include UserSupport

  before(:all) do
    change_setting('TwoFactorAuthDisabledForUser', true)
    SetupHelper.feature_setup

    @admin, = create_admin
    @user, @good_password = create_user
    @original_date_format = @user.user_preference.date_format
    @updated_date_format = @original_date_format == 'mm/dd/yyyy' ? 'dd/mm/yyyy' : 'mm/dd/yyyy'

    @page_layout = Admin::PageLayout.find_or_initialize_by(
      layout_name: 'user_profile', panel_name: 'user_profile_all', app_type_id: nil
    )
    @original_page_layout = if @page_layout.persisted?
                              @page_layout.attributes.slice('panel_label', 'options', 'panel_position', 'disabled')
                            end
    @page_layout.update!(current_admin: @admin,
                         panel_label: 'User Profile Tab',
                         options: "contains:\n  resources:\n    - user_preference\n",
                         panel_position: 1,
                         disabled: false)

    @user_access_control = Admin::UserAccessControl.find_or_initialize_by(
      resource_name: 'user_preferences', resource_type: 'table', access: 'create', app_type_id: nil,
      user_id: nil, role_name: nil
    )
    @original_access_disabled = @user_access_control.disabled if @user_access_control.persisted?
    @user_access_control.update!(current_admin: @admin, disabled: false)

    SetupHelper.reload_configs
  end

  after(:all) do
    if @original_page_layout
      @page_layout.update!(current_admin: @admin, **@original_page_layout.symbolize_keys)
    else
      @page_layout.update!(current_admin: @admin, disabled: true)
    end

    if @original_access_disabled.nil?
      @user_access_control.update!(current_admin: @admin, disabled: true)
    else
      @user_access_control.update!(current_admin: @admin, disabled: @original_access_disabled)
    end

    SetupHelper.reload_configs
  end

  before(:each) do
    login
  end

  it 'shows the preference fields and lets the user change and save a preference' do
    setup_browser_console_capture
    visit '/user_profile'
    finish_page_loading

    preference_tab = find_link('User Preference', wait: 10)
    preference_panel = preference_tab['data-target']
    unless page.has_css?("#{preference_panel}.in", wait: 5)
      preference_tab.click
    end
    expect(page).to have_css("#{preference_panel}.in", wait: 10)
    finish_page_loading
    finish_form_formatting

    within(preference_panel) do
      expect(page).to have_text('Timezone', wait: 10)
      expect(page).to have_text('Show date as')
      expect(page).to have_text('Show time as')
      expect(page).to have_text('Show date and time as')

      click_link('edit')
      finish_page_loading
      select @updated_date_format, from: 'Show date as'
      click_button 'Save'
    end
    finish_page_loading

    expect(@user.user_preference.reload.date_format).to eq(@updated_date_format)

    logs = get_browser_console_logs
    expect(logs[:logs].grep(/\AERROR:/)).to be_empty
  end
end
