# frozen_string_literal: true

# Feature: Register outcome of an outgoing call
#   As a user
#   I want to enter details about an outgoing phone call either I made, that was made by a rep, or I received
#   In order that activity can be searched and the tracker maintains an accurate view of contact activities
#   * I should be able to select a phone number that the user is logging actions against
#   * Actions related to a call can be rapidly selected
#   * Other related tracker and player information should be visible without additional effort to find it
#   * Other tracker activities can also be set without leaving the call log
#   * Player information can be edited without leaving the call log
#   * Where possible, tracker and phone record attributes can be updated through call log responses rather than needing to set them by hand (for example, bad phone number)
#   * A user should be able to record call activity on behalf of a rep that is not a user of Zeus

require 'rails_helper'

describe 'Register an incoming call', driver: :app_firefox_driver do
  include ActivityLogMain

  before :all do
    User.active.where.not(email: Settings::TemplateUserEmail).where.not(id: @user&.id).update_all(disabled: true)

    SetupHelper.feature_setup
    seed_database
    setup_database

    all_als = ActivityLog.active.select { |a| a.item_type_name == 'player_contact_phone' }
    if all_als.length > 1

      first = true
      all_als.each do |a|
        a.current_admin = @admin
        a.disable! unless first
        first = false
      end
    end

    ::ActivityLog.define_models

    ensure_user_matches_login_email
    setup_access :player_contacts
    setup_access :player_contacts, user: @user

    setup_access :activity_log__player_contact_phones, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, user: @user
    setup_access :activity_log__player_contact_phone__blank, resource_type: :activity_log_type, user: @user

    expect(@user.has_access_to?(:access, :table, :player_contacts)).to be_truthy
    @app_type = @user.app_type
    expect(ActivityLog.model_names).to include 'player_contact_phone'

    expect(@user.has_access_to?(:access, :table, :activity_log__player_contact_phones)).to be_truthy
    expect(@user.has_access_to?(:access, :activity_log_type, :activity_log__player_contact_phone__primary)).to be_truthy

    ac = Admin::AppConfiguration.find_default_app_config(@user.app_type, 'menu research label')
    ac&.disable!(@admin)
  end

  before :example do
    ensure_user_matches_login_email
    user_logs_in
    expect(User.find(@user.id).app_type_id).to eq @app_type.id
    expect(@user.has_access_to?(:access, :table, :player_contacts)).to be_truthy
  end

  it 'records the details of an incoming call' do
    user_views_contact_record

    show_top_ranked_phone_log

    expect_phone_log_to_be_visible

    indicate_user_received_a_call
    mark_call_status ActivityLogMain::CallConnected
    mark_next_step_status ActivityLogMain::NextStepComplete
    add_free_text_notes 'The player called us'
    save_log

    expect_log_to_show select_call_direction: ActivityLogMain::CallToStaff,
                       select_result: ActivityLogMain::CallConnected,
                       select_next_step: ActivityLogMain::NextStepComplete,
                       notes: 'The player called us'
  end

  it 'records the details of an outgoing call' do
    user_views_contact_record
    show_top_ranked_phone_log

    expect_phone_log_to_be_visible

    indicate_user_made_a_call
    mark_call_status ActivityLogMain::CallConnected
    mark_next_step_status ActivityLogMain::NextStepComplete
    add_free_text_notes 'I called the player'
    save_log

    expect_log_to_show select_call_direction: ActivityLogMain::CallToPlayer,
                       select_result: ActivityLogMain::CallConnected,
                       select_next_step: ActivityLogMain::NextStepComplete,
                       notes: 'I called the player'
  end

  it 'records the details of an outgoing call to a bad number' do
    user_views_contact_record
    show_top_ranked_phone_log

    expect_phone_log_to_be_visible

    indicate_user_made_a_call
    mark_call_status ActivityLogMain::CallBadNumber

    follow_up_date = (DateTime.now + 10.days)
    mark_next_step_status ActivityLogMain::NextStepCallBack, when: follow_up_date

    set_related_player_contact_rank ActivityLogMain::RankBadContact
    save_log

    expect_log_to_show select_call_direction: ActivityLogMain::CallToPlayer,
                       select_result: ActivityLogMain::CallBadNumber,
                       select_next_step: ActivityLogMain::NextStepCallBack,
                       follow_up_when: follow_up_date.strftime('%m/%d/%Y')

    expect_log_player_contact_to have_rank: ActivityLogMain::RankBadContact
  end

  # Feature: View call details within the context of the tracker records
  #   As a user
  #   I want to be able to see call details within the context of the tracker
  #   In order that I can view these details in the tracker panel alongside all other contact activities

  it 'adds a tracker records automatically for a logged call' do
    user_views_contact_record
    show_top_ranked_phone_log

    expect_phone_log_to_be_visible

    indicate_user_made_a_call
    mark_call_status ActivityLogMain::CallConnected
    mark_next_step_status ActivityLogMain::NextStepComplete
    select_related_protocol ActivityLogMain::StudyProtocol
    add_free_text_notes 'Look at me!'
    sleep 2
    save_log

    expect_log_to_show select_call_direction: ActivityLogMain::CallToPlayer,
                       select_result: ActivityLogMain::CallConnected,
                       select_next_step: ActivityLogMain::NextStepComplete,
                       protocol_id: ActivityLogMain::StudyProtocol

    expect_tracker_event_to_include DateTime.now, ActivityLogMain::StudyProtocol,
                                    ActivityLogMain::ActivitySubProcess, ActivityLogMain::PhoneLogProtocolEvent
  end
end
