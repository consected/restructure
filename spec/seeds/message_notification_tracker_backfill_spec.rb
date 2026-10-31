# frozen_string_literal: true

# Purpose: Verify the re-runnable task backfills notification tracker entries safely and resumably.
require 'rails_helper'

# Notifications opted out with no_tracker_entry cannot be distinguished from older notifications without history.

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

  def run_backfill_task(batch_size: 250, from_id: nil)
    task = Rake::Task['message_notifications:backfill_tracker_entries']
    task.reenable
    task.invoke(batch_size.to_s, from_id&.to_s)
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

  def create_legacy_notification(status:, event_date:, master: nil, master_id: nil, recipients: ['recipient@example.test'],
                                 subject: 'Legacy subject', message_type: 'email', user: nil,
                                 recipient_user_ids: nil)
    attributes = {
      app_type_id: user&.app_type_id,
      master_id: master_id.nil? ? master&.id : master_id,
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

  def stub_backfill_list_items(list_items)
    allow_any_instance_of(Messaging::MessageNotification).to receive(:list_item_for) do |_notification, list_type, id|
      list_items[[list_type, id]]
    end
  end

  def create_list_backfill_notification(targets:, status: 'complete')
    list_type = 'backfill_tracker_test_list_items'
    list_items = {}
    recipients = targets.each_with_index.map do |target, index|
      address = target.fetch(:address)
      contact = create_item({ data: address, rec_type: 'phone', source: 'nfl', rank: 10 }, target.fetch(:master))
      list_item = double('backfill tracker list item', data: address, master_id: -1, send_status: 'not sent')
      allow(list_item).to receive(:record_item).with(no_exception: true).and_return(contact)
      list_items[[list_type, index + 1]] = list_item
      { list_type:, id: index + 1 }.to_json
    end
    stub_backfill_list_items(list_items)

    notification = create_legacy_notification(
      status:, event_date: Time.zone.parse('2026-10-17 04:00:00'), master_id: -1,
      recipients:, subject: nil, message_type: 'sms'
    )
    [notification, targets]
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

    run_backfill_task

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

    run_backfill_task

    history = tracker_histories(notification).sole
    expect(history.master_id).to eq master.id
    expect(history.notes).to eq "type: email\nto: #{email}\nsubject: Legacy subject"
  end

  it 'does not create tracker history when no recipient email matches a player contact' do
    notification = create_legacy_notification(status: 'complete', event_date: Time.zone.parse('2026-10-18 07:00:00'),
                                              recipients: ['unmatched-recipient@example.test'])

    run_backfill_task

    expect(tracker_histories(notification)).to be_empty
  end

  it 'backfills SMS and email recipients instead of either temporary master' do
    cases = [-1, -2].flat_map do |temporary_master_id|
      %w[sms email].map do |message_type|
        address = message_type == 'email' ? "backfill-#{temporary_master_id}@example.test" : "+1617555#{temporary_master_id.abs}120"
        rec_type = message_type == 'email' ? 'email' : 'phone'
        target_master = create_master
        create_item({ data: address, rec_type:, source: rec_type == 'email' ? 'nflpa' : 'nfl', rank: 10 },
                    target_master)
        notification = create_legacy_notification(
          status: 'complete',
          event_date: Time.zone.parse('2026-10-19 08:15:00'),
          master_id: temporary_master_id,
          recipients: [address],
          subject: message_type == 'email' ? 'Legacy subject' : nil,
          message_type:
        )
        [notification, target_master, address, message_type]
      end
    end

    run_backfill_task

    cases.each do |notification, target_master, address, message_type|
      history = tracker_histories(notification).sole
      expect(history.master_id).to eq target_master.id
      expect(history.master_id).to be_positive
      expect(history.notes).to include("type: #{message_type}", "to: #{address}")
    end
  end

  it 'backfills failed list batches using each list record and recipient outcome' do
    sent_master = create_master
    failed_master = create_master
    sent_address = '+16175550128'
    failed_address = '+16175550129'
    sent_contact = create_item(
      { data: sent_address, rec_type: 'phone', source: 'nfl', rank: 10 }, sent_master
    )
    failed_contact = create_item(
      { data: failed_address, rec_type: 'phone', source: 'nfl', rank: 10 }, failed_master
    )
    list_type = 'tracker_test_list_items'
    sent_list_item = double('sent notification list item', data: sent_address, master_id: -1, send_status: 'sent')
    failed_list_item = double('failed notification list item', data: failed_address, master_id: -1,
                                                               send_status: 'not sent')
    allow(sent_list_item).to receive(:record_item).with(no_exception: true).and_return(sent_contact)
    allow(failed_list_item).to receive(:record_item).with(no_exception: true).and_return(failed_contact)
    stub_backfill_list_items(
      [
        [[list_type, 1], sent_list_item],
        [[list_type, 2], failed_list_item]
      ].to_h
    )
    notification = create_legacy_notification(
      status: 'failed',
      event_date: Time.zone.parse('2026-10-19 09:00:00'),
      master_id: -1,
      recipients: [
        { list_type:, id: 1 }.to_json,
        { list_type:, id: 2 }.to_json
      ],
      subject: nil,
      message_type: 'sms'
    )

    run_backfill_task

    histories = tracker_histories(notification).index_by(&:master_id)
    expect(histories.keys).to contain_exactly(sent_master.id, failed_master.id)
    expect(histories.fetch(sent_master.id).protocol_event.name).to eq 'Sent'
    expect(histories.fetch(sent_master.id).notes).to eq "type: sms\nto: #{sent_address}"
    expect(histories.fetch(failed_master.id).protocol_event.name).to eq 'Failed'
    expect(histories.fetch(failed_master.id).notes).to eq "type: sms\nto: #{failed_address}"
    expect(histories.keys).to all(be_positive)
  end

  it 'backfills a complete SMS with a master and no recipients without duplicating it' do
    master = create_master
    notification = create_legacy_notification(status: 'complete', event_date: Time.zone.parse('2026-10-17 05:00:00'),
                                              master:, recipients: [], subject: nil, message_type: 'sms')

    run_backfill_task

    history = tracker_histories(notification).sole
    expect(Classification::ProtocolEvent.find(history.protocol_event_id).name).to eq 'Sent'
    expect(history.master_id).to eq master.id
    expect(history.notes).to eq 'type: sms'
    original_history_ids = tracker_histories(notification).pluck(:id)

    run_backfill_task

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

    run_backfill_task

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

    run_backfill_task

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

    run_backfill_task

    expect(tracker_histories(existing).pluck(:id)).to eq existing_history_ids
    expect(tracker_histories(missing).sole.protocol_event.name).to eq 'Failed'
  end

  it 'does not create duplicate history when the migration is run repeatedly' do
    master = create_master
    notification = create_legacy_notification(status: 'complete', event_date: Time.zone.parse('2026-10-17 06:00:00'), master:)

    run_backfill_task
    original_history_ids = tracker_histories(notification).pluck(:id)
    run_backfill_task

    expect(tracker_histories(notification).pluck(:id)).to eq original_history_ids
  end

  it 'aborts with seed instructions when the General protocol is missing' do
    Classification::Protocol.active.where(name: 'General').update_all(name: "Hidden General #{SecureRandom.hex(4)}")

    error = nil
    begin
      run_backfill_task
    rescue SystemExit => e
      error = e
    end

    expect(error).to be_a(SystemExit)
    expect(error.status).not_to eq(0)
    expect(error.message).to match(/Run rails db:seed or rails db:migrate VERSION=20261027120000/)
  end

  it 'aborts with seed instructions when the Notification subprocess is missing' do
    protocol = Classification::Protocol.active.find_by!(name: 'General')
    protocol.sub_processes.active.where(name: 'Notification').update_all(
      name: "Hidden Notification #{SecureRandom.hex(4)}"
    )

    error = nil
    begin
      run_backfill_task
    rescue SystemExit => e
      error = e
    end

    expect(error).to be_a(SystemExit)
    expect(error.status).not_to eq(0)
    expect(error.message).to match(/Run rails db:seed or rails db:migrate VERSION=20261027120000/)
  end

  it 'aborts with seed instructions when Sent or Failed is missing' do
    protocol = Classification::Protocol.active.find_by!(name: 'General')
    notification = protocol.sub_processes.active.find_by!(name: 'Notification')
    notification.protocol_events.active.where(name: 'Failed').update_all(name: 'Hidden Failed')

    error = nil
    begin
      run_backfill_task
    rescue SystemExit => e
      error = e
    end

    expect(error).to be_a(SystemExit)
    expect(error.status).not_to eq(0)
    expect(error.message).to match(%r{General > Notification > Sent/Failed})
  end

  it 'continues to later notifications when tracker creation raises for one record' do
    master = create_master
    failing = create_legacy_notification(status: 'complete', event_date: Time.zone.parse('2026-10-15 04:00:00'), master:)
    succeeding = create_legacy_notification(status: 'complete', event_date: Time.zone.parse('2026-10-14 03:00:00'), master:)
    allow(Messaging::MessageNotificationTracker).to receive(:create_for).and_wrap_original do |original, notification, **options|
      raise StandardError, 'simulated tracker failure' if notification.id == failing.id

      original.call(notification, **options)
    end
    output = StringIO.new
    allow($stdout).to receive(:puts) { |*args| output.puts(*args) }

    expect do
      run_backfill_task
    end.to raise_error(SystemExit) { |error| expect(error.status).not_to eq(0) }

    expect(tracker_histories(failing)).to be_empty
    expect(tracker_histories(succeeding)).not_to be_empty
    expect(output.string).to include("Failed notification ids: #{failing.id}")
  end

  it 'finishes later targets, reports the notification id, and exits nonzero after a target failure' do
    failed_master = create_master
    succeeding_master = create_master
    notification, = create_list_backfill_notification(
      targets: [
        { master: failed_master, address: '+16175550150' },
        { master: succeeding_master, address: '+16175550151' }
      ]
    )
    allow(Master).to receive(:find).and_wrap_original do |original, master_id|
      raise ActiveRecord::RecordNotFound, 'simulated missing target' if master_id == failed_master.id

      original.call(master_id)
    end
    output = StringIO.new
    allow($stdout).to receive(:puts) { |*args| output.puts(*args) }

    expect do
      run_backfill_task
    end.to raise_error(SystemExit) { |error| expect(error.status).not_to eq(0) }

    expect(tracker_histories(notification).pluck(:master_id)).to eq [succeeding_master.id]
    expect(output.string).to include("Failed notification ids: #{notification.id}")
    expect(output.string).to include('1 failure(s)')
  end

  it 'resumes a partial target run by skipping the existing master and creating the missing one' do
    first_master = create_master
    second_master = create_master
    notification, = create_list_backfill_notification(
      targets: [
        { master: first_master, address: '+16175550152' },
        { master: second_master, address: '+16175550153' }
      ]
    )
    allow(Master).to receive(:find).and_wrap_original do |original, master_id|
      raise ActiveRecord::RecordNotFound, 'simulated partial run' if master_id == second_master.id

      original.call(master_id)
    end

    first_result = Messaging::MessageNotificationTracker.create_for(notification)
    expect(first_result).to have_attributes(created: 1, skipped: 0, failed: 1)
    expect(tracker_histories(notification).pluck(:master_id)).to eq [first_master.id]

    allow(Master).to receive(:find).and_call_original
    output = StringIO.new
    allow($stdout).to receive(:puts) { |*args| output.puts(*args) }
    run_backfill_task

    expect(tracker_histories(notification).pluck(:master_id)).to contain_exactly(first_master.id, second_master.id)
    expect(output.string).to include('1 target(s) skipped because an entry already existed')
    expect(output.string).to include('1 tracker entry/entries created')
  end

  it 'resumes from the requested notification id, inclusively' do
    master = create_master
    earlier = create_legacy_notification(
      status: 'complete', event_date: Time.zone.parse('2026-10-12 01:00:00'), master:
    )
    resume_at = create_legacy_notification(
      status: 'failed', event_date: Time.zone.parse('2026-10-11 01:00:00'), master:
    )

    run_backfill_task(from_id: resume_at.id)

    expect(tracker_histories(earlier)).to be_empty
    expect(tracker_histories(resume_at).sole.protocol_event.name).to eq 'Failed'
  end

  it 'honors batch_size and prints progress after each batch' do
    master = create_master
    notification = create_legacy_notification(
      status: 'complete', event_date: Time.zone.parse('2026-10-10 01:00:00'), master:
    )
    relation = double('eligible notification relation')
    allow(Messaging::MessageNotification).to receive(:where).with(status: %w[complete failed]).and_return(relation)
    expect(relation).to receive(:find_each).with(batch_size: 1).and_yield(notification)
    output = StringIO.new
    allow($stdout).to receive(:puts) { |*args| output.puts(*args) }

    run_backfill_task(batch_size: 1)

    expect(output.string).to include('Examined 1 notification(s)')
    expect(tracker_histories(notification)).to be_present
  end

  it 'backfills complete notifications through the re-runnable task' do
    master = create_master
    notification = create_legacy_notification(
      status: 'complete', event_date: Time.zone.parse('2026-10-13 02:00:00'), master:
    )

    run_backfill_task

    expect(tracker_histories(notification).sole.protocol_event.name).to eq 'Sent'
  end
end
