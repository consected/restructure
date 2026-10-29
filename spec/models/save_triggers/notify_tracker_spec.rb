# frozen_string_literal: true

# Purpose: Verify real notify-trigger and job flows create the expected tracker histories for every supported recipient source.
require 'rails_helper'

NOTIFY_TRACKER_RECIPIENT_SCENARIOS = {
  role_email: %i[email role],
  role_sms: %i[sms role],
  users_email: %i[email users],
  users_sms: %i[sms users],
  emails_email: %i[email emails],
  phones_sms: %i[sms phones],
  phone_records_sms: %i[sms phone_records]
}.freeze

RSpec.describe 'SaveTriggers::Notify tracker integration', type: :model do
  include ModelSupport
  include ActivityLogSupport
  include BulkMsgSupport
  include TestNoMasterDmRecSupport
  include AwsApiStubs
  include SaveTriggerNotifySpecSupport

  before :all do
    SetupHelper.setup_al_player_contact_phones
    SetupHelper.setup_al_gen_tests SaveTriggerNotifySpecSupport::AL_NAME_GEN_TEST, 'elt2_test', 'player_contact'
    Seeds::TrackerGeneralProtocol.create_protocol_events
  end

  before :example do |example|
    setup_notify_example
    setup_bulk_message_app if example.full_description.include?('phone_records_sms')
    User.where(id: @non_template_user_ids).each_with_index do |recipient, index|
      set_sms_number(recipient, "+16175550#{format('%03d', index)}")
    end
    @recipient_role = 'tracker-integration-recipient'
    Admin::UserRole.create!(app_type: @user.app_type, user: @user, role_name: @recipient_role, current_admin: @admin)
    allow(HandleMessageNotificationJob).to receive(:perform_later).and_return(nil)
  end

  def set_sms_number(user, sms_number)
    contact_info = user.contact_info || user.build_contact_info
    contact_info.assign_attributes(sms_number:, current_admin: @admin)
    contact_info.save!
  end

  def tracker_trigger_config(message_type, recipient_mode)
    config = {
      type: message_type.to_s,
      layout_template: message_type == :sms ? @layout_sms.name : @layout.name,
      content_template_text: 'Tracker integration content',
      subject: message_type == :email ? 'Tracker integration subject' : nil
    }
    case recipient_mode
    when :role
      config[:role] = @recipient_role
    when :users
      config[:users] = [@user.id]
    when :emails
      config[:emails] = ['notify-tracker@example.test']
    when :phones
      config[:phones] = ['6175550102']
      config[:default_country_code] = '1'
    when :phone_records
      bulk_message = @bulk_master.dynamic_model__zeus_bulk_messages.create!(
        status: 'sent',
        name: 'Tracker integration',
        channel: 'sms',
        message: 'Tracker integration content',
        send_date: Date.current,
        send_time: Time.current
      )
      @phone_record = @bulk_master.dynamic_model__zeus_bulk_message_recipients.create!(
        record_type: @player_contact.resource_name.singularize,
        record_id: @player_contact.id,
        data: @player_contact.data,
        rank: @player_contact.rank,
        response: nil,
        zeus_bulk_message_id: bulk_message.id
      )
      config[:phone_records] = [@phone_record.id]
      config[:list_type] = 'dynamic_model__zeus_bulk_message_recipients'
      config[:default_country_code] = '1'
    end
    config
  end

  def perform_notify(config, item: @al)
    trigger = SaveTriggers::Notify.new(config, item)
    trigger.perform
    trigger.instance_variable_get(:@message_notification)
  end

  def run_notification_job(notification, message_type, no_tracker_entry: nil, fail_sending: false)
    if message_type == :sms
      allow_any_instance_of(Messaging::NotificationSms).to receive(:send_sms) do
        raise StandardError, 'simulated send failure' if fail_sending

        double(message_id: 'tracker-integration-message')
      end
    else
      allow(NotificationMailer).to receive(:send_message_notification) do
        raise StandardError, 'simulated send failure' if fail_sending

        double(deliver_now: true)
      end
    end

    HandleMessageNotificationJob.perform_now(notification, no_tracker_entry:)
  end

  def notification_recipients(notification)
    if notification.recipient_hash_from_data
      notification.recipient_hash_from_data.filter_map { |recipient| recipient[:data] }
    elsif notification.sms?
      notification.recipient_sms_numbers || []
    else
      notification.recipient_emails || []
    end
  end

  def create_matching_player_contacts(master, addresses, message_type)
    master.current_user = @user
    rec_type = message_type == :sms ? 'phone' : 'email'
    addresses.each do |address|
      master.player_contacts.create!(
        current_user: @user,
        rec_type:,
        data: address,
        source: rec_type == 'email' ? 'nflpa' : 'nfl',
        rank: 10
      )
    end
  end

  def expect_tracker_history(notification, expected_master:, event_name:, recipients:)
    histories = TrackerHistory.where(item_type: notification.class.name, item_id: notification.id)
    if expected_master
      history = histories.sole
      expect(history.master_id).to eq expected_master.id
      expect(history.protocol.name).to eq 'General'
      expect(history.sub_process.name).to eq 'Notification'
      expect(history.protocol_event.name).to eq event_name
      notes = ["type: #{notification.message_type}"]
      notes << "to: #{recipients.join(', ')}" if recipients.any?
      notes << "subject: #{notification.subject}" if notification.subject.present?
      expect(history.notes).to eq notes.join("\n")
      expect(history.event_date).to eq notification.reload.updated_at
      expect(history.record_type).to eq notification.class.name
      expect(history.record_id).to eq notification.id
      expect(history.user_id).to eq notification.user_id
    else
      expect(histories).to be_empty
    end
  end

  NOTIFY_TRACKER_RECIPIENT_SCENARIOS.each do |scenario, (message_type, recipient_mode)|
    describe scenario do
      it 'creates a tracker history for a master-associated item' do
        config = tracker_trigger_config(message_type, recipient_mode)
        notification = perform_notify(config)

        run_notification_job(notification, message_type)

        expect(notification.reload.status).to eq 'complete'
        expect_tracker_history(
          notification,
          expected_master: @al.master,
          event_name: 'Sent',
          recipients: notification_recipients(notification)
        )
      end

      unless recipient_mode == :phone_records
        it 'matches recipients to a contact for an item with no master association' do
          setup_test_no_master_dm_rec_dynamic_model
          no_master_item = create_test_no_master_dm_rec(sample_test_no_master_dm_rec_attrs)
          config = tracker_trigger_config(message_type, recipient_mode)
          notification = perform_notify(config, item: no_master_item)
          recipients = notification_recipients(notification)
          matching_master = create_master(@user)
          create_matching_player_contacts(matching_master, recipients, message_type)

          run_notification_job(notification, message_type)

          expect(notification.reload.status).to eq 'complete'
          expect_tracker_history(
            notification,
            expected_master: matching_master,
            event_name: 'Sent',
            recipients: notification_recipients(notification)
          )
        end

        it 'does not create history for an item with no master or matching contact' do
          setup_test_no_master_dm_rec_dynamic_model
          no_master_item = create_test_no_master_dm_rec(sample_test_no_master_dm_rec_attrs)
          config = tracker_trigger_config(message_type, recipient_mode)
          notification = perform_notify(config, item: no_master_item)

          run_notification_job(notification, message_type)

          expect(notification.reload.status).to eq 'complete'
          expect_tracker_history(
            notification,
            expected_master: nil,
            event_name: 'Sent',
            recipients: notification_recipients(notification)
          )
        end
      end
    end
  end

  it 'suppresses history when no_tracker_entry is true' do
    config = tracker_trigger_config(:email, :emails).merge(no_tracker_entry: true)
    notification = perform_notify(config)

    run_notification_job(notification, :email, no_tracker_entry: true)

    expect(notification.reload.status).to eq 'complete'
    expect_tracker_history(notification, expected_master: nil, event_name: 'Sent', recipients: [])
  end

  it 'records Failed when sending raises' do
    config = tracker_trigger_config(:email, :emails)
    notification = perform_notify(config)

    expect { run_notification_job(notification, :email, fail_sending: true) }
      .to raise_error(FphsException, /simulated send failure/)

    expect(notification.reload.status).to eq 'failed'
    expect_tracker_history(
      notification,
      expected_master: @al.master,
      event_name: 'Failed',
      recipients: notification_recipients(notification)
    )
  end
end
