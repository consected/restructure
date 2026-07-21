# frozen_string_literal: true

require 'rails_helper'

# System tests for versioned phone log templates in the UI.
#
# Purpose:
# - Reproduce the issue-1078 user flow at UI level:
#   1) create a phone log record with one definition version,
#   2) update the phone log definition,
#   3) reload UI and open phone log panel again.
# - Verify historical phone log records continue to render after the definition update.
#
# This complements Jasmine coverage in _fpa_prepare_template_configs_spec.js
# by validating end-to-end behavior through the browser.
describe 'Versioned phone log templates', driver: $browser_driver do
  include ActivityLogMain

  def set_up_user_access
    ensure_user_matches_login_email
    setup_access :player_contacts
    setup_access :player_contacts, user: @user

    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, user: @user
    setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, user: @user

    expect(@user.has_access_to?(:read, :general, :app_type)).to be_truthy
    expect(@user.has_access_to?(:access, :table, :player_contacts)).to be_truthy
    @app_type = @user.app_type

    expect(@user.has_access_to?(:access, :table, :activity_log__player_contact_phones)).to be_truthy
    expect(@user.has_access_to?(:access, :activity_log_type, :activity_log__player_contact_phone__primary)).to be_truthy

    ac = Admin::AppConfiguration.find_default_app_config(@user.app_type, 'menu research label')
    ac&.disable!(@admin)

    @app_type.app_configurations.where(name: 'notes field format').update_all(disabled: true)
    Admin::AppConfiguration.create!(
      name: 'notes field format',
      value: 'markdown',
      app_type: @app_type,
      current_admin: @admin
    )
  end

  def search_for_player(player)
    click_link 'Research'
    finish_page_loading
    finish_form_formatting

    within '#master-search-simple-form' do
      fill_in 'Last name', with: player.last_name
      fill_in 'First or nick name', with: player.first_name
      finish_page_loading
      finish_form_formatting

      search_button = find_button('search', wait: 5)
      scroll_into_view(search_button)
      begin
        search_button.click
      rescue Selenium::WebDriver::Error::ElementClickInterceptedError
        finish_page_loading
        finish_form_formatting
        search_button = find_button('search', wait: 5)
        scroll_into_view(search_button)
        search_button.click
      end
    end

    dismiss_modal
    finish_form_formatting
    dismiss_modal
  end

  def update_phone_log_definition!
    activity_log = ActivityLog.active.find_by(name: ActivityLogMain::ActivityLogName, rec_type: 'phone', item_type: 'player_contact')
    expect(activity_log).not_to be_nil

    previous_versions_count = activity_log.all_versions.length
    activity_log.current_admin = @admin

    # Updating extra_log_types reliably creates a new definition version while
    # preserving the same core phone-log flow used by these system specs.
    activity_log.extra_log_types = <<~YAML
      primary:
        label: Primary #{SecureRandom.hex(3)}
        fields:
          - select_call_direction
          - select_who
          - called_when
          - select_result
          - select_next_step
          - follow_up_when
          - notes
          - protocol_id
          - set_related_player_contact_rank

      blank_log:
        label: Blank log
        fields:
          - select_who
          - called_when
          - select_next_step
          - follow_up_when
          - notes
          - protocol_id
    YAML

    activity_log.save!
    activity_log.reload

    expect(activity_log.all_versions.length).to eq(previous_versions_count + 1)

    [previous_versions_count, activity_log.all_versions.length]
  end

  before :all do
    SetupHelper.setup_al_gen_tests ActivityLogMain::ActivityLogName, nil, 'player_contact', rec_type: 'phone'

    create_user(create_master: false) unless @user

    SetupHelper.feature_setup
    setup_database

    @original_disable_vdef = Settings::DisableVDef
    change_setting('DisableVDef', false)

    all_als = ActivityLog.active.select { |a| a.item_type_name == 'player_contact_phone' }
    if all_als.length > 1
      first = true
      all_als.each do |a|
        a.current_admin = @admin
        a.disable! unless first
        first = false
      end
    end

    ActivityLog.define_models
  end

  after :all do
    change_setting('DisableVDef', @original_disable_vdef)
  end

  before :example do
    create_user(create_master: false)
    set_up_user_access
    ensure_user_matches_login_email
    user_logs_in
    expect(User.find(@user.id).app_type_id).to eq @app_type.id
  end

  it 'renders historical phone log records after activity log definition update' do
    user_views_contact_record
    show_top_ranked_phone_log
    expect_phone_log_to_be_visible

    @saved_notes = "versioned-template-spec-#{SecureRandom.hex(4)}"

    indicate_user_received_a_call
    mark_call_status ActivityLogMain::CallConnected
    mark_next_step_status ActivityLogMain::NextStepComplete
    add_free_text_notes @saved_notes
    save_log

    expect_log_to_show select_call_direction: ActivityLogMain::CallToStaff,
                       select_result: ActivityLogMain::CallConnected,
                       select_next_step: ActivityLogMain::NextStepComplete,
                       notes: @saved_notes

    saved_log = ActivityLog::PlayerContactPhone.order(:id).last
    expect(saved_log).not_to be_nil

    update_phone_log_definition!

    visit '/'
    finish_form_formatting
    search_for_player(@player)
    expand_master_record(master_id: @master.id)

    show_top_ranked_phone_log

    # If historical template config resolution fails, this panel does not render
    # correctly after the definition update.
    expect(page).to have_loaded_phone_log
  end
end
