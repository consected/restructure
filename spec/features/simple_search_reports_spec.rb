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

  after(:all) do
  end
end
