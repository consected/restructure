# frozen_string_literal: true

require 'rails_helper'

# System tests for the clear user roles functionality in the admin panel (issue #671).
# Tests verify the UI workflow for disabling all roles for a specified user
# in a specified app type, using a form similar to the "Copy Roles" form.
#
# NOTE: The model tests in spec/models/admin/user_role_spec.rb provide complete coverage
# of the underlying clear_user_roles method.
describe 'admin clear user roles', js: true, driver: $browser_driver do
  include ModelSupport
  include AdminActionsSetup
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup

    @setup_admin = Admin.active.first || Admin.first || Admin.create!(
      email: "setup_admin_#{rand(1_000_000)}@test.com",
      password: 'Pass1234!',
      password_confirmation: 'Pass1234!',
      disabled: false
    )

    @app_type_1 = Admin::AppType.active.first || Admin::AppType.create!(
      name: 'test_app',
      label: 'Test App',
      current_admin: @setup_admin
    )
  end

  before(:each) do
    make_an_admin
    login_as(@admin, scope: :admin)

    @user_with_roles, = create_user(email: "clear_user_#{rand(1_000_000_000)}@testing.com")

    @role_names = %w[researcher data_entry coordinator]
    @role_names.each do |role_name|
      Admin::UserRole.create!(
        user: @user_with_roles,
        app_type: @app_type_1,
        role_name: role_name,
        current_admin: @admin
      )
    end
  end

  # Reuse the same chosen helper from the copy spec
  def select_from_chosen_by_id(field_id, value)
    chosen_id = "#{field_id}_chosen"
    find("##{chosen_id}").click

    results_selector = 'body > .chosen-container.chosen-with-drop .chosen-results li.active-result'
    expect(page).to have_css(results_selector, wait: 5)

    results = all(results_selector)
    matching = results.find { |r| r.text.downcase == value.downcase }
    raise "Could not find option '#{value}' in dropdown. Available: #{results.map(&:text).inspect}" unless matching

    matching.click
    sleep 0.3
  end

  it 'clears all roles for a user in an app type' do
    visit admin_user_roles_path
    finish_page_loading

    expect(page).to have_content('Clear All Roles for a User')

    # Expand the clear roles form
    find('a[href="#clear-roles-block"]').click
    sleep 0.5

    # Select user
    select_from_chosen_by_id('clear_user_id', @user_with_roles.email)

    within '#clear-roles-block' do
      # Select app type
      app_type_select = find('select[name="clear_app_type_id"]')
      available_options = app_type_select.all('option').reject { |o| o.text.blank? }
      raise 'No app types available in dropdown' unless available_options.any?

      select available_options.first.text, from: 'clear_app_type_id'

      # Submit the form
      click_button 'clear'
    end

    finish_page_loading

    # Verify success message
    expect(page).to have_content("#{@user_with_roles.email} had 3 #{'role'.pluralize(3)} cleared for app #{@app_type_1.name}")

    # Verify roles were disabled in database
    active_roles = Admin::UserRole.active.where(user: @user_with_roles, app_type: @app_type_1)
    expect(active_roles.count).to eq 0
  end

  it 'shows appropriate message when user has no roles to clear' do
    user_no_roles, = create_user(email: "no_roles_#{rand(1_000_000_000)}@testing.com")

    visit admin_user_roles_path
    finish_page_loading

    find('a[href="#clear-roles-block"]').click
    sleep 0.5

    select_from_chosen_by_id('clear_user_id', user_no_roles.email)

    within '#clear-roles-block' do
      app_type_select = find('select[name="clear_app_type_id"]')
      available_options = app_type_select.all('option').reject { |o| o.text.blank? }
      select available_options.first.text, from: 'clear_app_type_id'

      click_button 'clear'
    end

    finish_page_loading

    expect(page).to have_content("#{user_no_roles.email} had 0 roles cleared for app #{@app_type_1.name}")
  end

  it 'shows an error when no user is selected' do
    visit admin_user_roles_path
    finish_page_loading

    find('a[href="#clear-roles-block"]').click
    sleep 0.5

    within '#clear-roles-block' do
      # Don't select a user, just pick an app type and submit
      app_type_select = find('select[name="clear_app_type_id"]')
      available_options = app_type_select.all('option').reject { |o| o.text.blank? }
      select available_options.first.text, from: 'clear_app_type_id'

      click_button 'clear'
    end

    finish_page_loading

    expect(page).to have_content('A user must be selected to clear roles')
  end
end
