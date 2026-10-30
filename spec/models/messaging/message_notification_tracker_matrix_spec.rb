# frozen_string_literal: true

# Purpose: Exercise notification tracker behavior across channels, recipient sources, status changes, and nonnegative master targets.
require 'rails_helper'

module MessageNotificationTrackerMatrix
  MESSAGE_MODES = {
    email: %i[raw users empty],
    sms: %i[raw users users_without_phone phone_records empty]
  }.freeze
  DIRECT_STATUSES = {
    complete: 'complete',
    failed: 'failed',
    in_progress: 'in progress',
    nil: nil
  }.freeze
  HANDLED_STATUSES = %i[complete failed].freeze
end

RSpec.describe 'Message notification tracker status matrix', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport

  before :all do
    create_admin
    seed_database
    Seeds::TrackerGeneralProtocol.create_protocol_events
    @owner_user, = create_user
    @recipient_user, = create_user
    @recipient_user.create_contact_info!(sms_number: '+16175550120', current_admin: @admin)
    @recipient_without_phone, = create_user
    @matrix_master = create_master(@owner_user)
    @email_layout = create_tracker_layout(:email)
    @sms_layout = create_tracker_layout(:sms)
  end

  def create_tracker_layout(message_type)
    Admin::MessageTemplate.create!(
      name: "tracker matrix #{message_type} #{SecureRandom.hex(5)}",
      message_type:,
      template_type: :layout,
      template: '{{main_content}}',
      current_admin: @admin
    )
  end

  def recipient_address(message_type, mode)
    return @recipient_user.email if mode == :users && message_type == :email
    return @recipient_user.contact_info.sms_number if mode == :users && message_type == :sms
    return '+16175550120' if %i[raw phone_records].include?(mode) && message_type == :sms
    return "matrix-#{mode}@example.test" if message_type == :email && mode == :raw

    nil
  end

  def notification_attributes(message_type, mode, with_master:)
    address = recipient_address(message_type, mode)
    attributes = {
      app_type: @owner_user.app_type,
      user: @owner_user,
      master: with_master ? @matrix_master : nil,
      item_type: UserPreference.name,
      layout_template_name: (message_type == :sms ? @sms_layout : @email_layout).name,
      content_template_text: 'Matrix notification content',
      message_type:,
      subject: message_type == :email ? 'Matrix subject' : nil
    }

    case mode
    when :raw
      attributes[:recipient_data] = [address]
    when :users
      attributes[:recipient_user_ids] = [@recipient_user.id]
    when :users_without_phone
      attributes[:recipient_user_ids] = [@recipient_without_phone.id]
    when :phone_records
      attributes[:recipient_data] = [{ list_type: 'matrix_phone_records', id: 1, data: address }]
    when :empty
      attributes[:recipient_data] = []
    end
    attributes
  end

  def resolved_recipients(message_type, mode)
    address = recipient_address(message_type, mode)
    address.present? ? [address] : []
  end

  def create_matching_contact(message_type, mode)
    address = recipient_address(message_type, mode)
    return unless address

    rec_type = message_type == :sms ? 'phone' : 'email'
    create_item({ data: address, rec_type:, source: rec_type == 'email' ? 'nflpa' : 'nfl', rank: 10 },
                @matrix_master)
  end

  def create_notification(message_type, mode, with_master:)
    Messaging::MessageNotification.create!(notification_attributes(message_type, mode, with_master:))
  end

  def tracker_histories(notification)
    TrackerHistory.where(item_id: notification.id, item_type: notification.class.name)
  end

  def expect_tracker_result(notification, message_type:, mode:, with_master:, status:, contact_match:)
    terminal = %w[complete failed].include?(status)
    list_recipients = mode == :phone_records
    recipients = resolved_recipients(message_type, mode)
    expected_master_ids = if terminal && ((with_master && !list_recipients) || (contact_match && recipients.any?))
                            [@matrix_master.id]
                          else
                            []
                          end
    histories = tracker_histories(notification).order(:master_id).to_a

    expect(histories.length).to eq expected_master_ids.length
    expect(histories.map(&:master_id)).to eq expected_master_ids
    histories.each do |history|
      expected_event = status == 'complete' ? 'Sent' : 'Failed'
      expected_recipients = (with_master && !list_recipients) || contact_match ? recipients : []
      expected_notes = ["type: #{message_type}"]
      expected_notes << "to: #{expected_recipients.join(', ')}" if expected_recipients.any?
      expected_notes << 'subject: Matrix subject' if message_type == :email

      expect(history.protocol_event.name).to eq expected_event
      expect(history.notes).to eq expected_notes.join("\n")
      expect(history.event_date).to eq notification.reload.updated_at
      expect(history.record_type).to eq notification.class.name
      expect(history.record_id).to eq notification.id
      expect(history.user_id).to eq @owner_user.id
    end
  end

  scenarios = []
  MessageNotificationTrackerMatrix::MESSAGE_MODES.each do |message_type, modes|
    modes.each do |mode|
      [true, false].each do |with_master|
        contact_matches = with_master ? [nil] : [true, false]
        MessageNotificationTrackerMatrix::DIRECT_STATUSES.each do |status_name, status|
          contact_matches.each do |contact_match|
            scenarios << [message_type, mode, with_master, :direct, status_name, status, contact_match]
          end
        end
        MessageNotificationTrackerMatrix::HANDLED_STATUSES.each do |handled_status|
          contact_matches.each do |contact_match|
            scenarios << [message_type, mode, with_master, :handle, handled_status, handled_status.to_s, contact_match]
          end
        end
      end
    end
  end

  scenarios.each do |scenario|
    message_type, mode, with_master, path, status_name, status, contact_match = scenario
    it "records #{message_type} #{mode} with master=#{with_master} via #{path} at #{status_name} (contact=#{contact_match.inspect})" do
      create_matching_contact(message_type, mode) if contact_match
      notification = create_notification(message_type, mode, with_master:)

      if path == :direct
        notification.update!(status:)
      else
        sender = notification.recipient_hash_from_data ? :generate_and_send_for_recipient_records : :generate_and_send
        if status == 'failed'
          allow(notification).to receive(sender).and_raise(StandardError, 'simulated send failure')
          expect { notification.handle_notification_now }
            .to raise_error(FphsException, /simulated send failure/)
        else
          allow(notification).to receive(sender) do
            expect(tracker_histories(notification)).to be_empty
            true
          end
          notification.handle_notification_now
        end
      end

      expect(notification.reload.status).to eq(status)
      expect_tracker_result(notification, message_type:, mode:, with_master:, status:, contact_match:)

      expect(tracker_histories(notification).where('master_id < 0')).to be_empty
      expect(Tracker.where(item_type: notification.class.name, item_id: notification.id)
                    .where('master_id < 0')).to be_empty
    end
  end

  [-1, -2].each do |temporary_master_id|
    %i[email sms].each do |message_type|
      it "matches #{message_type} matrix recipients instead of tracking temporary master #{temporary_master_id}" do
        mode = :raw
        create_matching_contact(message_type, mode)
        notification = create_notification(message_type, mode, with_master: false)
        notification.update_column(:master_id, temporary_master_id)
        notification.update!(status: 'complete')

        expect_tracker_result(
          notification,
          message_type:,
          mode:,
          with_master: false,
          status: 'complete',
          contact_match: true
        )
        expect(tracker_histories(notification).where('master_id < 0')).to be_empty
        expect(Tracker.where(item_type: notification.class.name, item_id: notification.id)
                      .where('master_id < 0')).to be_empty
      end
    end
  end
end
