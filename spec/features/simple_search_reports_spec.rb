# frozen_string_literal: true

require 'rails_helper'
SetupHelper.feature_setup

describe 'simple search reports', js: true, driver: :app_firefox_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:all) do
    @admin, = create_admin

    seed_database
    create_data_set_outside_tx

    gs = Classification::GeneralSelection.all
    gs.each { |g| g.current_admin = @admin; g.create_with = true; g.edit_always = true; g.save! }

    @user, @good_password = create_user
    @good_email = @user.email

    Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general, resource_name: :create_master, current_admin: @admin, user: @user
    Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general, resource_name: :export_csv, current_admin: @admin, user: @user

    expect(@user.can?(:create_master)).to be_truthy
    expect(@user.can?(:export_csv)).to be_truthy
  end

  before :each do
    user = User.where(email: @good_email).first

    expect(user).to be_a User
    expect(user.id).to equal @user.id

    # login_as @user, scope: :user

    login
  end

  it 'should export CSV for a simple search' do
    visit '/masters/search'

    pl = player_list.first

    expect(PlayerInfo.where(last_name: pl[:last_name]).first).not_to be nil

    within '#simple_search_master' do
      fill_in 'Last name', with: pl[:last_name]
      click_button 'search'
    end

    expect(page).to have_css('#master_results_block')

    within '#simple_search_master' do
      click_button 'csv'
      sleep 2
    end

    # If there is an alert it is possibly because there are no results to export.
    # Check this is not the case
    expect(page).not_to have_css('.alert')

    within '#simple_search_master' do
      fill_in 'Last name', with: ''
      click_button 'search'
      sleep 1
      click_button 'csv'
    end

    expect(page).to have_css('.alert')

    expect(find('.alert').text).to match(/no results to export/)
  end

  after(:all) do
  end
end
