# frozen_string_literal: true

# Purpose: Verify sent and failed message notifications, including master-targeted notifications without recipients, are backfilled safely.
require 'rails_helper'

RSpec.describe 'Message notification tracker history backfill' do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport

  before :all do
    @original_allow_migrations = Settings::AllowDynamicMigrations
    change_setting('AllowDynamicMigrations', true)
    create_admin
    seed_database
    create_dynamic_contact_model
  end

  after :all do
    @contact_model&.reload&.disable!(@admin)
    change_setting('AllowDynamicMigrations', @original_allow_migrations)
  end

  before :example do
    create_admin
  end

  def run_backfill_migration
    migration_path = Rails.root.join('db/migrate/20261027130000_backfill_message_notification_tracker_history.rb')
    load migration_path.to_s unless Object.const_defined?(:BackfillMessageNotificationTrackerHistory, false)

    Object.const_get(:BackfillMessageNotificationTrackerHistory).new.up
  end

  def create_dynamic_contact_model
    @contact_model = DynamicModel.new(
      current_admin: @admin,
      name: 'Backfill Tracker Contact',
      table_name: "backfill_tracker_contact#{SecureRandom.hex(4)}s",
      schema_name: 'dynamic_test',
      primary_key_name: :id,
      foreign_key_name: :master_id,
      category: :test,
      field_list: 'rec_type data rank source disabled',
      options: <<~YAML
        _db_columns:
          disabled:
            type: boolean
        default:
          view_options:
            view_handlers:
              - contact
      YAML
    )
    rec_type_item = "#{@contact_model.model_association_name}_rec_type"
    selector_values = %w[email phone].map do |rec_type|
      [rec_type_item, rec_type.titleize, rec_type]
    end
    selector_values.push(
      ["#{@contact_model.model_association_name}_source", 'Backfill test source', 'test'],
      ["#{@contact_model.model_association_name}_rank", 'Primary', 10]
    )
    selector_values.each do |item_type, name, value|
      Classification::GeneralSelection.create!(current_admin: @admin, item_type:, name:, value:)
    end
    @contact_model.save!
    @contact_model.update_tracker_events
    association_prefix = @contact_model.model_class.name.ns_underscore
    @dynamic_email_resource = "#{association_prefix}_emails"
    @dynamic_phone_resource = "#{association_prefix}_phones"
  end

  def create_legacy_notification(status:, event_date:, master: nil, recipients: ['recipient@example.test'],
                                 subject: 'Legacy subject', message_type: 'email', user: nil,
                                 recipient_user_ids: nil)
    attributes = {
      app_type_id: user&.app_type_id,
      master_id: master&.id,
      message_type:,
      recipient_data: recipients,
      recipient_user_ids:,
      subject:,
      status: nil,
      user_id: user&.id,
      created_at: event_date - 1.day,
      updated_at: event_date
    }
    result = Messaging::MessageNotification.insert!(attributes)
    notification = Messaging::MessageNotification.find(result.rows.first.first)
    notification.update_columns(status:, updated_at: event_date) if status
    notification.reload
  end

  def tracker_histories(notification)
    TrackerHistory.where(item_type: notification.class.name, item_id: notification.id)
  end

  it 'backfills complete and failed notifications using their updated_at without modifying source records' do
    master = create_master
    completed_date = Time.zone.parse('2026-10-20 09:15:00')
    failed_date = Time.zone.parse('2026-10-21 10:30:00')
    in_progress_date = Time.zone.parse('2026-10-22 11:45:00')
    pending_date = Time.zone.parse('2026-10-23 12:00:00')
    invalid_status_date = Time.zone.parse('2026-10-24 13:15:00')
    completed = create_legacy_notification(status: 'complete', event_date: completed_date, master:)
    failed = create_legacy_notification(status: 'failed', event_date: failed_date, master:)
    in_progress = create_legacy_notification(status: 'in progress', event_date: in_progress_date, master:)
    pending = create_legacy_notification(status: nil, event_date: pending_date, master:)
    invalid_status = create_legacy_notification(status: 'delivered', event_date: invalid_status_date, master:)
    notifications = [completed, failed, in_progress, pending, invalid_status]
    source_timestamps = notifications.to_h { |notification| [notification.id, notification.updated_at] }

    run_backfill_migration

    completed_history = tracker_histories(completed).sole
    expect(Classification::ProtocolEvent.find(completed_history.protocol_event_id).name).to eq 'Sent'
    expect(completed_history.event_date).to eq completed.updated_at
    expect(completed_history.master_id).to eq master.id

    failed_history = tracker_histories(failed).sole
    expect(Classification::ProtocolEvent.find(failed_history.protocol_event_id).name).to eq 'Failed'
    expect(failed_history.event_date).to eq failed.updated_at
    expect(tracker_histories(in_progress)).to be_empty
    expect(tracker_histories(pending)).to be_empty
    expect(tracker_histories(invalid_status)).to be_empty
    actual_timestamps = notifications.map { |notification| notification.reload.updated_at }
    expected_timestamps = notifications.map { |notification| source_timestamps.fetch(notification.id) }
    expect(actual_timestamps).to eq expected_timestamps
  end

  it 'matches recipient email addresses to player contacts when a notification has no master' do
    master = create_master
    email = 'matched-recipient@example.test'
    create_item({ data: email, rec_type: 'email', source: 'nflpa', rank: 10 }, master)
    notification = create_legacy_notification(status: 'complete', event_date: Time.zone.parse('2026-10-19 08:00:00'),
                                              recipients: [email])

    run_backfill_migration

    history = tracker_histories(notification).sole
    expect(history.master_id).to eq master.id
    expect(history.notes).to eq "type: email\nto: #{email}\nsubject: Legacy subject"
  end

  it 'does not create tracker history when no recipient email matches a player contact' do
    notification = create_legacy_notification(status: 'complete', event_date: Time.zone.parse('2026-10-18 07:00:00'),
                                              recipients: ['unmatched-recipient@example.test'])

    run_backfill_migration

    expect(tracker_histories(notification)).to be_empty
  end

  it 'backfills a complete SMS with a master and no recipients without duplicating it' do
    master = create_master
    notification = create_legacy_notification(status: 'complete', event_date: Time.zone.parse('2026-10-17 05:00:00'),
                                              master:, recipients: [], subject: nil, message_type: 'sms')

    run_backfill_migration

    history = tracker_histories(notification).sole
    expect(Classification::ProtocolEvent.find(history.protocol_event_id).name).to eq 'Sent'
    expect(history.master_id).to eq master.id
    expect(history.notes).to eq 'type: sms'
    original_history_ids = tracker_histories(notification).pluck(:id)

    run_backfill_migration

    expect(tracker_histories(notification).pluck(:id)).to eq original_history_ids
  end

  it 'backfills SMS recipients resolved from user phone numbers for a master' do
    user, = create_user
    user.create_contact_info!(sms_number: '+15165550102', current_admin: @admin)
    master = create_master(user)
    notification = create_legacy_notification(
      status: 'complete',
      event_date: Time.zone.parse('2026-10-17 05:30:00'),
      master:,
      recipients: nil,
      subject: nil,
      message_type: 'sms',
      user:,
      recipient_user_ids: [user.id]
    )

    run_backfill_migration

    history = tracker_histories(notification).sole
    expect(history.master_id).to eq master.id
    expect(history.protocol_event.name).to eq 'Sent'
    expect(history.notes).to eq "type: sms\nto: +15165550102"
  end

  it 'uses configured dynamic contacts when backfilling masterless notifications' do
    user, = create_user
    access_control = Admin::UserAccessControl.where(
      app_type: user.app_type,
      resource_type: :table,
      resource_name: @contact_model.resource_name,
      role_name: [nil, ''],
      user:
    ).first_or_initialize
    access_control.assign_attributes(access: :create, current_admin: @admin, disabled: user.disabled)
    access_control.save!
    master = create_master(user)
    phone_number = '(516) 555-0102'
    association = Master.reflect_on_association(@dynamic_phone_resource.to_sym)
    master.current_user = user
    master.public_send(association.name).create!(
      current_user: user,
      rec_type: 'phone',
      data: phone_number,
      rank: 10,
      source: 'test',
      disabled: false
    )
    resources = { email: @dynamic_email_resource, phone: @dynamic_phone_resource }.to_yaml
    add_app_config(user.app_type, 'message notification contact resources', resources)
    notification = create_legacy_notification(
      status: 'complete',
      event_date: Time.zone.parse('2026-10-17 06:00:00'),
      recipients: ['+15165550102'],
      subject: nil,
      message_type: 'sms',
      user:
    )

    run_backfill_migration

    history = tracker_histories(notification).sole
    expect(history.master_id).to eq master.id
    expect(history.notes).to eq "type: sms\nto: +15165550102"
  end

  it 'preserves existing histories and creates only missing histories in a mixed backfill' do
    master = create_master
    existing = create_legacy_notification(status: 'complete', event_date: Time.zone.parse('2026-10-17 06:30:00'), master:)
    missing = create_legacy_notification(status: 'failed', event_date: Time.zone.parse('2026-10-17 07:00:00'), master:)
    Messaging::MessageNotificationTracker.create_for(existing)
    existing_history_ids = tracker_histories(existing).pluck(:id)

    run_backfill_migration

    expect(tracker_histories(existing).pluck(:id)).to eq existing_history_ids
    expect(tracker_histories(missing).sole.protocol_event.name).to eq 'Failed'
  end

  it 'does not create duplicate history when the migration is run repeatedly' do
    master = create_master
    notification = create_legacy_notification(status: 'complete', event_date: Time.zone.parse('2026-10-17 06:00:00'), master:)

    run_backfill_migration
    original_history_ids = tracker_histories(notification).pluck(:id)
    run_backfill_migration

    expect(tracker_histories(notification).pluck(:id)).to eq original_history_ids
  end

  it 'creates missing General notification protocol records before backfilling' do
    Admin.where(email: 'auto-admin@dummy.aaa').delete_all
    admin_count = Admin.count
    expected_admin = Admin.active.find_by(email: Settings::AdminEmail.downcase) || Admin.active.first
    Classification::Protocol.active.where(name: 'General').update_all(name: "Hidden General #{SecureRandom.hex(4)}")
    master = create_master
    notification = create_legacy_notification(status: 'complete', event_date: Time.zone.parse('2026-10-16 05:00:00'), master:)

    run_backfill_migration

    expect(Admin.count).to eq(admin_count)
    expect(Admin.find_by(email: 'auto-admin@dummy.aaa')).to be_nil

    protocol = Classification::Protocol.active.find_by!(name: 'General')
    notification_protocol = protocol.sub_processes.active.find_by!(name: 'Notification')
    records = [protocol, notification_protocol, *notification_protocol.protocol_events.active]
    expect(records.map(&:admin_id)).to all(eq(expected_admin.id))

    history = tracker_histories(notification).sole
    expect(history.protocol.sub_processes.active.find_by!(name: 'Notification')
      .protocol_events.active.find_by!(name: 'Sent')).to be_present
  end

  it 'continues to later notifications when tracker creation raises for one record' do
    master = create_master
    failing = create_legacy_notification(status: 'complete', event_date: Time.zone.parse('2026-10-15 04:00:00'), master:)
    succeeding = create_legacy_notification(status: 'complete', event_date: Time.zone.parse('2026-10-14 03:00:00'), master:)
    allow(Messaging::MessageNotificationTracker).to receive(:create_for).and_wrap_original do |original, notification|
      raise StandardError, 'simulated tracker failure' if notification.id == failing.id

      original.call(notification)
    end

    expect { run_backfill_migration }.not_to raise_error

    expect(tracker_histories(failing)).to be_empty
    expect(tracker_histories(succeeding)).not_to be_empty
  end
end
