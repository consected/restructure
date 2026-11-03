# frozen_string_literal: true

# Purpose: Verify tracker targets, per-target retries, and failures for message notifications.
require 'rails_helper'

RSpec.describe Messaging::MessageNotification, type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport

  before :example do
    create_admin
    seed_database
    Seeds::TrackerGeneralProtocol.create_protocol_events
    @owner_user, = create_user
    @recipient_user, = create_user
    @master = create_master(@owner_user)
    @sms_layout = Admin::MessageTemplate.create!(
      name: "tracker sms layout #{SecureRandom.hex(5)}",
      message_type: :sms,
      template_type: :layout,
      template: '{{main_content}}',
      current_admin: @admin
    )
    @email_layout = Admin::MessageTemplate.create!(
      name: "tracker email layout #{SecureRandom.hex(5)}",
      message_type: :email,
      template_type: :layout,
      template: '{{main_content}}',
      current_admin: @admin
    )
  end

  def create_tracker_target_master
    create_master(@owner_user)
  end

  def create_tracker_contact(master:, rec_type:, data:)
    setup_access :player_contacts, user: @owner_user
    master.current_user = @owner_user
    master.player_contacts.create!(
      current_user: @owner_user,
      rec_type:,
      data:,
      source: rec_type == 'email' ? 'nflpa' : 'nfl',
      rank: 10
    )
  end

  def create_tracker_notification(master_id:, message_type:, recipient_data:, status: 'complete')
    layout = message_type == 'email' ? @email_layout : @sms_layout
    notification = described_class.create!(
      app_type: @owner_user.app_type,
      item_type: UserPreference.name,
      user: @owner_user,
      master: @master,
      layout_template_name: layout.name,
      content_template_text: 'Notification content',
      message_type:,
      subject: message_type == 'email' ? 'Tracker target subject' : nil,
      recipient_data:
    )
    notification.update_column(:master_id, master_id)
    notification.update!(status:)
    notification
  end

  def create_tracker_list_item(id:, data:, record_item: nil, send_status: 'not sent')
    list_item = double('notification list item', id:, data:, send_status:)
    allow(list_item).to receive(:record_item).with(no_exception: true).and_return(record_item)
    list_item
  end

  def stub_tracker_list_items(list_items)
    items_by_id = list_items.index_by(&:id)
    relation_class = Class.new do
      define_method(:initialize) { |record| @record = record }
      define_method(:first) { @record }
    end
    list_item_class = Class.new
    list_item_class.define_singleton_method(:active) { self }
    list_item_class.define_singleton_method(:where) do |id:|
      relation_class.new(items_by_id[id])
    end
    allow(ModelReference).to receive(:to_record_class_for_type).and_return(list_item_class)
  end

  def tracker_list_recipient_data(list_items, include_data: true)
    list_items.map do |list_item|
      recipient = { list_type: 'tracker_test_list_items', id: list_item.id }
      recipient[:data] = list_item.data if include_data
      recipient
    end
  end

  def create_tracker_list_notification(list_items:, master_id:, message_type: 'sms', status: 'complete',
                                       include_data: true)
    stub_tracker_list_items(list_items)
    create_tracker_notification(
      master_id:,
      message_type:,
      recipient_data: tracker_list_recipient_data(list_items, include_data:),
      status:
    )
  end

  def create_tracker_multi_target_notification
    failed_master = create_tracker_target_master
    succeeding_master = create_tracker_target_master
    failed_contact = create_tracker_contact(master: failed_master, rec_type: 'phone', data: '+16175550140')
    succeeding_contact = create_tracker_contact(master: succeeding_master, rec_type: 'phone', data: '+16175550141')
    list_items = [
      create_tracker_list_item(id: 20, data: failed_contact.data, record_item: failed_contact),
      create_tracker_list_item(id: 21, data: succeeding_contact.data, record_item: succeeding_contact)
    ]
    notification = create_tracker_list_notification(list_items:, master_id: -1)

    [notification, failed_master, succeeding_master]
  end

  def notification_tracker_histories(notification)
    TrackerHistory.where(item_type: notification.class.name, item_id: notification.id).order(:master_id, :id)
  end

  def expect_notification_tracker(notification, master:, message_type:, event_name:, recipients:)
    history = notification_tracker_histories(notification).find_by!(master_id: master.id)
    expect(history.protocol_event.name).to eq event_name
    notes = ["type: #{message_type}"]
    notes << "to: #{recipients.join(', ')}" if recipients.any?
    notes << 'subject: Tracker target subject' if message_type == 'email'
    expect(history.notes).to eq notes.join("\n")
    expect(history.event_date).to eq notification.reload.updated_at
    expect(history.user_id).to eq @owner_user.id
    history
  end

  it 'does not create a Failed master history when an SMS to a user has no phone number' do
    notification = described_class.create!(
      user: @owner_user,
      master: @master,
      recipient_user_ids: [@recipient_user],
      layout_template_name: @sms_layout.name,
      content_template_text: 'Notification content',
      message_type: :sms
    )
    expect(notification.recipient_sms_numbers).to be_empty

    expect do
      HandleMessageNotificationJob.perform_now(notification)
    end.to raise_error(FphsException, /No recipients to SMS/)

    expect(TrackerHistory.where(item_type: notification.class.name, item_id: notification.id)).to be_empty
  end

  it 'recognizes nested legacy recipient user ids as end-user targets' do
    notification = described_class.new
    allow(notification).to receive(:recipient_user_ids).and_return([[1, 76]])

    expect(notification.targets_end_users?).to be(true)
  end

  it 'ignores user-addressed notifications and returns an ignored result' do
    notification = described_class.create!(
      user: @owner_user,
      master: @master,
      recipient_user_ids: [@recipient_user.id],
      layout_template_name: @sms_layout.name,
      content_template_text: 'Notification content',
      message_type: :sms
    )
    notification.update_column(:status, 'complete')
    expect(Rails.logger).to receive(:info).with(a_string_including('user-addressed'))

    result = Messaging::MessageNotificationTracker.create_for(notification)

    expect(result).to have_attributes(created: 0, skipped: 0, failed: 0, ignored: 1, errors: [])
    expect(notification_tracker_histories(notification)).to be_empty
  end

  describe 'temporary notification masters' do
    [-1, -2].each do |temporary_master_id|
      %w[sms email].each do |message_type|
        it "matches #{message_type} recipients instead of tracking temporary master #{temporary_master_id}" do
          address = message_type == 'email' ? "temporary-#{temporary_master_id}@example.test" : "+1617555#{temporary_master_id.abs}120"
          rec_type = message_type == 'email' ? 'email' : 'phone'
          target_master = create_tracker_target_master
          create_tracker_contact(master: target_master, rec_type:, data: address)
          notification = create_tracker_notification(
            master_id: temporary_master_id,
            message_type:,
            recipient_data: [address]
          )

          expect(notification_tracker_histories(notification).pluck(:master_id)).to eq [target_master.id]
          expect_notification_tracker(notification, master: target_master, message_type:, event_name: 'Sent',
                                                    recipients: [address])
          expect(notification_tracker_histories(notification).where(master_id: ...0)).to be_empty
        end
      end
    end
  end

  describe 'list recipients' do
    it 'ignores list-style participant matching for a user-addressed notification' do
      target_master = create_tracker_target_master
      address = '+16175550120'
      create_tracker_contact(master: target_master, rec_type: 'phone', data: address)
      notification = described_class.create!(
        user: @owner_user,
        master: @master,
        recipient_user_ids: [@recipient_user.id],
        recipient_data: [{ list_type: 'tracker_test_list_items', id: 1, data: address }],
        layout_template_name: @sms_layout.name,
        content_template_text: 'Notification content',
        message_type: :sms
      )
      notification.update_column(:master_id, -1)
      allow(notification).to receive(:list_item_for).and_return(nil)

      notification.update!(status: 'complete')

      expect(notification_tracker_histories(notification)).to be_empty
    end

    it 'uses the referenced record master for an SMS recipient' do
      target_master = create_tracker_target_master
      contact = create_tracker_contact(master: target_master, rec_type: 'phone', data: '+16175550120')
      list_item = create_tracker_list_item(id: 1, data: contact.data, record_item: contact)
      notification = create_tracker_list_notification(list_items: [list_item], master_id: -1)

      expect(notification_tracker_histories(notification).pluck(:master_id)).to eq [target_master.id]
      expect_notification_tracker(notification, master: target_master, message_type: 'sms', event_name: 'Sent',
                                                recipients: [contact.data])
    end

    it 'matches list item data when its referenced record is unavailable' do
      target_master = create_tracker_target_master
      address = '+16175550121'
      create_tracker_contact(master: target_master, rec_type: 'phone', data: address)
      list_item = create_tracker_list_item(id: 2, data: address)
      notification = create_tracker_list_notification(list_items: [list_item], master_id: -1, include_data: false)

      expect(notification_tracker_histories(notification).pluck(:master_id)).to eq [target_master.id]
      expect_notification_tracker(notification, master: target_master, message_type: 'sms', event_name: 'Sent',
                                                recipients: [address])
    end

    it 'matches the hash address when the active list item is missing' do
      target_master = create_tracker_target_master
      address = '+16175550122'
      create_tracker_contact(master: target_master, rec_type: 'phone', data: address)
      stub_tracker_list_items([])
      notification = create_tracker_notification(
        master_id: -1,
        message_type: 'sms',
        recipient_data: [{ list_type: 'tracker_test_list_items', id: 3, data: address }]
      )

      expect(notification_tracker_histories(notification).pluck(:master_id)).to eq [target_master.id]
      expect_notification_tracker(notification, master: target_master, message_type: 'sms', event_name: 'Sent',
                                                recipients: [address])
    end

    it 'does not create an entry when neither the record nor address resolves' do
      list_item = create_tracker_list_item(id: 4, data: '+16175550999')
      notification = create_tracker_list_notification(list_items: [list_item], master_id: -1)

      expect(notification_tracker_histories(notification)).to be_empty
    end

    it 'combines recipients belonging to the same master into one entry' do
      target_master = create_tracker_target_master
      first_contact = create_tracker_contact(master: target_master, rec_type: 'phone', data: '+16175550123')
      second_contact = create_tracker_contact(master: target_master, rec_type: 'phone', data: '+16175550124')
      list_items = [
        create_tracker_list_item(id: 5, data: first_contact.data, record_item: first_contact),
        create_tracker_list_item(id: 6, data: second_contact.data, record_item: second_contact)
      ]
      notification = create_tracker_list_notification(list_items:, master_id: -1)

      expect(notification_tracker_histories(notification).pluck(:master_id)).to eq [target_master.id]
      expect_notification_tracker(notification, master: target_master, message_type: 'sms', event_name: 'Sent',
                                                recipients: [first_contact.data, second_contact.data])
    end

    it 'creates one entry per distinct recipient master' do
      first_master = create_tracker_target_master
      second_master = create_tracker_target_master
      first_contact = create_tracker_contact(master: first_master, rec_type: 'phone', data: '+16175550125')
      second_contact = create_tracker_contact(master: second_master, rec_type: 'phone', data: '+16175550126')
      list_items = [
        create_tracker_list_item(id: 7, data: first_contact.data, record_item: first_contact),
        create_tracker_list_item(id: 8, data: second_contact.data, record_item: second_contact)
      ]
      notification = create_tracker_list_notification(list_items:, master_id: -1)

      expect(notification_tracker_histories(notification).pluck(:master_id)).to eq [first_master.id, second_master.id].sort
      expect_notification_tracker(notification, master: first_master, message_type: 'sms', event_name: 'Sent',
                                                recipients: [first_contact.data])
      expect_notification_tracker(notification, master: second_master, message_type: 'sms', event_name: 'Sent',
                                                recipients: [second_contact.data])
    end

    it 'uses list item addresses when failed-batch hashes have no data' do
      target_master = create_tracker_target_master
      address = '+16175550127'
      contact = create_tracker_contact(master: target_master, rec_type: 'phone', data: address)
      list_item = create_tracker_list_item(id: 9, data: address, record_item: contact)
      notification = create_tracker_list_notification(
        list_items: [list_item], master_id: -1, status: 'failed', include_data: false
      )

      expect_notification_tracker(notification, master: target_master, message_type: 'sms', event_name: 'Failed',
                                                recipients: [address])
    end

    it 'marks an already-sent recipient Sent when a later list recipient fails' do
      sent_master = create_tracker_target_master
      failed_master = create_tracker_target_master
      sent_contact = create_tracker_contact(master: sent_master, rec_type: 'phone', data: '+16175550128')
      failed_contact = create_tracker_contact(master: failed_master, rec_type: 'phone', data: '+16175550129')
      list_items = [
        create_tracker_list_item(id: 10, data: sent_contact.data, record_item: sent_contact, send_status: 'sent'),
        create_tracker_list_item(id: 11, data: failed_contact.data, record_item: failed_contact)
      ]
      notification = create_tracker_list_notification(
        list_items:, master_id: -1, status: 'failed', include_data: false
      )

      expect_notification_tracker(notification, master: sent_master, message_type: 'sms', event_name: 'Sent',
                                                recipients: [sent_contact.data])
      expect_notification_tracker(notification, master: failed_master, message_type: 'sms', event_name: 'Failed',
                                                recipients: [failed_contact.data])
    end

    it 'matches email list recipients as email addresses without phone formatting' do
      target_master = create_tracker_target_master
      address = 'list-recipient@example.test'
      create_tracker_contact(master: target_master, rec_type: 'email', data: address)
      list_item = create_tracker_list_item(id: 12, data: address)
      notification = create_tracker_list_notification(
        list_items: [list_item], master_id: -1, message_type: 'email', include_data: false
      )

      expect(notification_tracker_histories(notification).pluck(:master_id)).to eq [target_master.id]
      expect_notification_tracker(notification, master: target_master, message_type: 'email', event_name: 'Sent',
                                                recipients: [address])
    end

    it 'uses recipient masters instead of a real or holding notification master' do
      notification_master = create_tracker_target_master
      matched_master = create_tracker_target_master
      record_master = create_tracker_target_master
      address = '+16175550130'
      create_tracker_contact(master: matched_master, rec_type: 'phone', data: address)
      holding_record = double('holding record', master_id: -1)
      record_contact = create_tracker_contact(master: record_master, rec_type: 'phone', data: '+16175550131')
      list_items = [
        create_tracker_list_item(id: 13, data: address, record_item: holding_record),
        create_tracker_list_item(id: 14, data: record_contact.data, record_item: record_contact)
      ]
      notification = create_tracker_list_notification(list_items:, master_id: notification_master.id)

      expected_ids = [matched_master.id, record_master.id].sort
      expect(notification_tracker_histories(notification).pluck(:master_id)).to eq expected_ids
      expect(notification_tracker_histories(notification).pluck(:master_id)).not_to include(notification_master.id, -1, -2)
      expect_notification_tracker(notification, master: matched_master, message_type: 'sms', event_name: 'Sent',
                                                recipients: [address])
      expect_notification_tracker(notification, master: record_master, message_type: 'sms', event_name: 'Sent',
                                                recipients: [record_contact.data])
    end
  end

  describe 'phone contact matching' do
    it 'matches formatted persisted contacts against E.164 recipients' do
      target_master = create_tracker_target_master
      contact = create_tracker_contact(master: target_master, rec_type: 'phone', data: '(617) 555-1212')
      notification = create_tracker_notification(
        master_id: -1, message_type: 'sms', recipient_data: ['+16175551212']
      )

      expect(contact.reload).to be_persisted
      expect(notification_tracker_histories(notification).pluck(:master_id)).to eq [target_master.id]
    end

    it 'does not match a bare recipient number to a contact with extension digits' do
      target_master = create_tracker_target_master
      create_tracker_contact(master: target_master, rec_type: 'phone', data: '(617) 555-1212 ext. 77')
      notification = create_tracker_notification(
        master_id: -1, message_type: 'sms', recipient_data: ['+16175551212']
      )

      # Contact extensions are retained, so they cannot match a recipient number without an extension.
      expect(notification_tracker_histories(notification)).to be_empty
    end
  end

  describe 'contact discovery errors' do
    let(:unknown_contact_resource) { 'unknown_tracker_phone_contacts' }

    def configure_tracker_phone_resource(value)
      add_app_config(@owner_user.app_type, 'message notification contact resources', value)
    end

    it 'raises a collected failure for an invalid contact association in strict mode' do
      notification = create_tracker_notification(
        master_id: -1, message_type: 'sms', recipient_data: ['+16175551299']
      )
      configure_tracker_phone_resource({ phone: unknown_contact_resource }.to_yaml)

      error = nil
      expect do
        Messaging::MessageNotificationTracker.create_for(notification, strict: true)
      end.to raise_error(Messaging::MessageNotificationTracker::TargetCreationError) { |exception| error = exception }

      expect(error.result).to have_attributes(failed: 1)
      expect(error.result.errors.first[:master_id]).to be_nil
      expect(error.result.errors.first[:error].message).to include(unknown_contact_resource)
    end

    it 'logs invalid contact associations without raising in non-strict mode' do
      notification = create_tracker_notification(
        master_id: -1, message_type: 'sms', recipient_data: ['+16175551298']
      )
      configure_tracker_phone_resource({ phone: unknown_contact_resource }.to_yaml)
      expect(Rails.logger).to receive(:warn).with(a_string_including(unknown_contact_resource))

      expect do
        Messaging::MessageNotificationTracker.create_for(notification)
      end.not_to raise_error
      expect(notification_tracker_histories(notification)).to be_empty
    end

    it 'raises a collected failure for invalid YAML contact configuration in strict mode' do
      notification = create_tracker_notification(
        master_id: -1, message_type: 'sms', recipient_data: ['+16175551297']
      )
      configure_tracker_phone_resource('phone: [unterminated')

      error = nil
      expect do
        Messaging::MessageNotificationTracker.create_for(notification, strict: true)
      end.to raise_error(Messaging::MessageNotificationTracker::TargetCreationError) { |exception| error = exception }

      expect(error.result).to have_attributes(failed: 1)
      expect(error.result.errors.first[:master_id]).to be_nil
      expect(error.result.errors.first[:error].message).to include('message notification contact resources')
    end

    it 'raises a collected failure for a non-hash contact configuration in strict mode' do
      notification = create_tracker_notification(
        master_id: -1, message_type: 'sms', recipient_data: ['+16175551296']
      )
      configure_tracker_phone_resource(false.to_yaml)

      error = nil
      expect do
        Messaging::MessageNotificationTracker.create_for(notification, strict: true)
      end.to raise_error(Messaging::MessageNotificationTracker::TargetCreationError) { |exception| error = exception }

      expect(error.result).to have_attributes(failed: 1)
      expect(error.result.errors.first[:error].message).to include('expected a YAML hash')
    end

    it 'creates a resolvable list target before raising for another recipient discovery error' do
      target_master = create_tracker_target_master
      contact = create_tracker_contact(master: target_master, rec_type: 'phone', data: '+16175551295')
      list_items = [
        create_tracker_list_item(id: 30, data: contact.data, record_item: contact),
        create_tracker_list_item(id: 31, data: '+16175551294')
      ]
      notification = create_tracker_list_notification(list_items:, master_id: -1)
      notification_tracker_histories(notification).delete_all
      configure_tracker_phone_resource({ phone: unknown_contact_resource }.to_yaml)

      error = nil
      expect do
        Messaging::MessageNotificationTracker.create_for(notification, strict: true)
      end.to raise_error(Messaging::MessageNotificationTracker::TargetCreationError) { |exception| error = exception }

      expect(error.result).to have_attributes(created: 1, failed: 1)
      expect(error.result.errors.first[:master_id]).to be_nil
      expect(notification_tracker_histories(notification).pluck(:master_id)).to eq [target_master.id]
    end
  end

  describe '.create_for options' do
    it 'skips an existing target while creating a missing target' do
      notification, existing_master, missing_master = create_tracker_multi_target_notification
      notification_tracker_histories(notification).where(master_id: missing_master.id).delete_all

      result = Messaging::MessageNotificationTracker.create_for(notification, skip_existing: true)

      expect(result).to have_attributes(created: 1, skipped: 1, failed: 0)
      expect(notification_tracker_histories(notification).pluck(:master_id)).to contain_exactly(
        existing_master.id, missing_master.id
      )
    end

    it 'continues to later targets in non-strict mode when a target fails' do
      notification, failed_master, succeeding_master = create_tracker_multi_target_notification
      notification_tracker_histories(notification).delete_all
      allow(Master).to receive(:find).and_wrap_original do |original, master_id|
        raise ActiveRecord::RecordNotFound, 'simulated missing master' if master_id == failed_master.id

        original.call(master_id)
      end

      result = Messaging::MessageNotificationTracker.create_for(notification)

      expect(result).to have_attributes(created: 1, skipped: 0, failed: 1)
      expect(notification_tracker_histories(notification).pluck(:master_id)).to eq [succeeding_master.id]
    end

    it 'tries all targets then raises collected errors in strict mode' do
      notification, failed_master, succeeding_master = create_tracker_multi_target_notification
      notification_tracker_histories(notification).delete_all
      allow(Master).to receive(:find).and_wrap_original do |original, master_id|
        raise ActiveRecord::RecordNotFound, 'simulated missing master' if master_id == failed_master.id

        original.call(master_id)
      end

      error = nil
      begin
        Messaging::MessageNotificationTracker.create_for(notification, strict: true)
      rescue Messaging::MessageNotificationTracker::TargetCreationError => e
        error = e
      end

      expect(error).to be_a(Messaging::MessageNotificationTracker::TargetCreationError)
      expect(error.result).to have_attributes(created: 1, skipped: 0, failed: 1)
      expect(notification_tracker_histories(notification).pluck(:master_id)).to eq [succeeding_master.id]
    end
  end
end
