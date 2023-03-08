# frozen_string_literal: true

require 'rails_helper'

describe 'Create a BHS subject and activity', driver: :app_firefox_driver do
  include MasterDataSupport
  include FeatureSupport
  include BhsActivityLogSetup
  include BhsImportConfig
  include BhsUi
  include BhsExpectations
  include BhsActions

  def bhs_app_type
    Admin::AppType.active.find_by(name: BhsImportConfig.bhs_app_name)
  end

  before :all do
    BhsImportConfig.import_config
    SetupHelper.feature_setup
    change_setting('TwoFactorAuthDisabledForUser', false)
    seed_database
    create_data_set_outside_tx

    create_admin

    @app_type = bhs_app_type
    # By default the app limits access to only those masters that have a BHS assignment
    # already made in another app.
    # To avoid this, just disable this restriction for now.
    Admin::UserAccessControl.active
                            .where(app_type_id: bhs_app_type.id,
                                   resource_type: %i[external_id_assignments limited_access])
                            .update_all(disabled: true)

    # Can't seem to avoid an error without this
    BhsAssignment.definition.update_tracker_events

    create_user_for_login

    create_user_for_login
    setup_access_as :ra
    @ra = { user: @user, email: @good_email, pw: @good_password }

    create_user_for_login
    setup_access_as :pi
    @pi = { user: @user, email: @good_email, pw: @good_password }

    m = Master.last
    m.current_user = @ra[:user]
    setup_access :bhs_assignments, access: :create, user: @ra[:user]
    expect(@ra[:user].has_access_to?(:create, :table, :bhs_assignments)).to be_truthy

    bmaxobj = BhsAssignment.order(bhs_id: :desc).first
    bmax = bmaxobj&.bhs_id || 200_197_832

    b = m.bhs_assignments.build(bhs_id: bmax + 1)
    b.save!
  end

  before :each do
    @app_type = bhs_app_type
    ActivityLog.define_models
  end

  def as_user(role)
    @user = role[:user]
    @good_email = role[:email]
    @good_password = role[:pw]
    login_to_app
  end

  def create_master_as_ra
    user_logout if user_logged_in?
    as_user @ra
    login_to_app
    expect(@user.app_type_id).to eq bhs_app_type.id
    a = Admin::UserAccessControl.active.find_by(user: @user, app_type: bhs_app_type, resource_type: :general,
                                                resource_name: 'create_master').access
    expect(a).to eq 'read'
    expect(@user.can?(:create_master)).to be_truthy
    create_bhs_master
    # click_button BhsUi::SearchButton
  end

  def login_to_app
    if user_logged_in?
      logged_in_user = find('a[data-do-action="show-user-options"]')[:title]
      if logged_in_user == @good_email
        visit '/'
      else
        # puts "Logout user #{logged_in_user} and login as #{@good_email}"
        user_logout
      end
    end
    user_logs_in

    select_app BhsUi::AppName
  end

  it 'allows a user to create a subject record' do
    as_user @ra

    create_bhs_master
    expect_master_record
  end

  it 'finds a subject as PI' do
    create_master_as_ra
    as_user @pi

    search_player ''

    expand_master 0
    expect_master_record
    expect_bhs_tabs :pi
  end

  it 'finds a subject as RA' do
    create_master_as_ra
    as_user @ra

    search_player ''

    expand_master 0
    expect_master_record
    expect_bhs_tabs :ra
    expand_master_record_tab 'external ids'
  end
end
