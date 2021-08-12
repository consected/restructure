# frozen_string_literal: true

require 'rails_helper'

describe 'simple search reports', js: true, driver: :app_firefox_driver do
  include ModelSupport
  include MasterDataSupport
  include FeatureSupport

  before(:all) do
    SetupHelper.feature_setup

    @admin, = create_admin

    seed_database
    create_data_set_outside_tx
    create_data_set
    gs = Classification::GeneralSelection.all
    gs.each do |g|
      g.current_admin = @admin
      g.create_with = true
      g.edit_always = true
      g.save!
    end

    @user, @good_password = create_user
    @good_email = @user.email

    Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general,
                                     resource_name: :create_master, current_admin: @admin, user: @user
    Admin::UserAccessControl.create! app_type_id: @user.app_type_id, access: :read, resource_type: :general,
                                     resource_name: :export_csv, current_admin: @admin, user: @user

    expect(@user.can?(:create_master)).to be_truthy
    expect(@user.can?(:export_csv)).to be_truthy
    pl = player_list.first
    expect(PlayerInfo.where(last_name: pl[:last_name]).first).not_to be nil
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
    user = User.where(email: @good_email).first
    expect(user.can?(:export_csv)).to be_truthy

    pl = player_list.first

    expect(PlayerInfo.where(last_name: pl[:last_name]).first).not_to be nil

    within '#simple_search_master' do
      fill_in 'Last name', with: pl[:last_name]
      sleep 1
      click_button 'search'
    end

    expect(page).to have_css('#master_results_block')

    expect(page).to have_css('#expand-simple-form')
    if has_css?('#expand-simple-form.collapse')
      click_button '#expand-simple-form.collapse'
      has_css? '.btn-csv'
    end

    # within '#simple_search_master' do
    #   click_button 'csv'
    #   sleep 2
    # end

    # If there is an alert it is possibly because there are no results to export.
    # Check this is not the case
    expect(page).not_to have_css('.alert')

    within '#simple_search_master' do
      fill_in 'Last name', with: ''
      sleep 1
      click_button 'search'
      sleep 5
      # click_button 'csv'
    end

    expect(page).to have_css('.alert')

    expect(find('.alert').text).to match(/no results to export/)
  end

  after(:all) do
  end
end
