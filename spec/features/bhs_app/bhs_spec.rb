require 'rails_helper'

describe "Create a BHS subject and activity", driver: :app_firefox_driver do

  include BhsActivityLogSetup
  include BhsImportConfig
  include BhsUi

  before :all do
    create_bhs_config
    enable_user_app_access BhsUi::AppShortName
    # Ensure we have adequate access controls
    setup_access :create_master, resource_type: :general, access: :read

    setup_access :player_infos
    setup_access :player_contacts

    setup_access :bhs_assignments
    setup_access :activity_log__bhs_assignments
    setup_access :activity_log__bhs_assignment__primary, resource_type: :activity_log_type


    user_logs_in

    select_app BhsUi::AppName
  end

  it "allows a user to create a subject record" do
    click_link BhsUi::CreateSubjectRecord
    fill_in BhsUi::BhsIdField, with: '234612'
    click_button BhsUi::NewSubjectCreateButton
  end

  it "finds a subject" do
    click_link BhsUi::SearchPlayer
    click_button BhsUi::SearchButton

    expect(page).to have_css('.resuls-panel .master-panel')
  end



end
