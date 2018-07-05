require 'rails_helper'

describe "Create a BHS subject and activity", driver: :app_firefox_driver do

  include FeatureSupport
  include BhsActivityLogSetup
  include BhsImportConfig
  include BhsUi
  include BhsExpectations
  include BhsActions

  before :all do
    create_bhs_config

    create_user_for_login
    setup_access_as :ra
    @ra = {user: @user, email: @good_email, pw: @good_password}

    create_user_for_login
    setup_access_as :pi
    @pi = {user: @user, email: @good_email, pw: @good_password}

    m = Master.create(current_user: @ra[:user])
    b = m.bhs_assignments.build(bhs_id:'2523565')
    b.save!
  end

  before :each do
  end

  def as_user role
    @user = role[:user]
    @good_email = role[:email]
    @good_password = role[:pw]
    login_to_app
  end

  def create_master_as_ra
    user_logout if user_logged_in?
    as_user @ra
    login_to_app
    expect(@user.app_type_id).to eq @app_type.id
    a = Admin::UserAccessControl.active.where(user: @user, app_type: @app_type, resource_type: :general, resource_name: 'create_master').first.access
    expect(a).to eq 'read'
    expect(@user.can? :create_master).to be_truthy
    create_bhs_master
    # click_button BhsUi::SearchButton
  end

  def login_to_app
    visit "/" if user_logged_in?
    user_logs_in
    select_app BhsUi::AppName
  end

  it "allows a user to create a subject record" do
    as_user @ra

    create_bhs_master
    expect_master_record
  end

  it "finds a subject as PI" do

    create_master_as_ra

    as_user @pi


    search_player ""


    expand_master 0
    expect_master_record
    expect_bhs_tabs :pi

  end

  it "finds a subject as RA" do
    create_master_as_ra
    as_user @ra


    search_player ""

    expand_master 0
    expect_master_record
    expect_bhs_tabs :ra
    expand_master_record_tab 'external ids'

  end


end
