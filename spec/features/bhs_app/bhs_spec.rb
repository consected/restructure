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
    @ra = @user

    create_user_for_login
    setup_access_as :pi
    @pi = @user
  end

  before :each do
    create_master_as_ra
  end

  def create_master_as_ra
    user_logout if user_logged_in?
    @user = @ra
    login_to_app
    create_bhs_master
    click_button BhsUi::SearchButton
  end

  def login_to_app
    visit "/" if user_logged_in?
    user_logs_in
    select_app BhsUi::AppName
  end

  it "allows a user to create a subject record" do
    @user = @ra
    login_to_app
    create_bhs_master
    expect_master_record
  end

  it "finds a subject as PI" do

    @user = @pi
    login_to_app

    search_player ""


    expect_master_record
    expect_bhs_tabs :pi

  end

  it "finds a subject as RA" do
    @user = @ra
    login_to_app

    search_player ""

    expect_master_record
    expect_bhs_tabs :ra
    expand_master_record_tab 'external ids'

  end


end
