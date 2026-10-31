# frozen_string_literal: true

# Purpose: Verify the General tracker seed and its data migration create notification tracking records idempotently.
require 'rails_helper'

RSpec.describe Seeds::TrackerGeneralProtocol do
  let(:admin) { Seeds.auto_admin }

  def hide_existing_general_protocols
    Classification::Protocol.where(name: 'General').update_all(name: 'Existing General protocol')
  end

  def expect_general_notification_events
    protocol = Classification::Protocol.active.find_by(name: 'General')
    expect(protocol).to be_present

    notification = protocol.sub_processes.active.find_by(name: 'Notification')
    expect(notification).to be_present
    expect(notification.protocol_events.active.pluck(:name)).to contain_exactly('Sent', 'Failed')
  end

  def run_notification_protocol_migration
    migration_path = Rails.root.join('db/migrate/20261027120000_add_notification_protocol_events_to_tracker_general_protocol.rb')
    expect(migration_path.file?).to be(true), "Expected migration file at #{migration_path}"

    load migration_path.to_s unless Object.const_defined?(:AddNotificationProtocolEventsToTrackerGeneralProtocol, false)

    Object.const_get(:AddNotificationProtocolEventsToTrackerGeneralProtocol).new.up
  end

  describe '.create_protocol_events' do
    it 'creates General > Notification > Sent and Failed while preserving Communications events' do
      hide_existing_general_protocols

      described_class.create_protocol_events

      expect_general_notification_events
      protocol = Classification::Protocol.active.find_by!(name: 'General')
      communications = protocol.sub_processes.active.find_by!(name: 'Communications')
      expect(communications.protocol_events.active.pluck(:name)).to contain_exactly(
        'communication (incoming)', 'communication (outgoing)'
      )
    end

    it 'does not create duplicate General notification records when run repeatedly' do
      hide_existing_general_protocols

      2.times { described_class.create_protocol_events }

      expect(Classification::Protocol.active.where(name: 'General').count).to eq(1)
      protocol = Classification::Protocol.active.find_by!(name: 'General')
      notification = protocol.sub_processes.active.where(name: 'Notification')
      expect(notification.count).to eq(1)
      expect(notification.first.protocol_events.active.where(name: %w[Sent Failed]).count).to eq(2)
    end
  end

  describe '.setup' do
    it 'creates General when another active protocol exists outside the test environment' do
      hide_existing_general_protocols
      Classification::Protocol.create!(name: 'Other active protocol', current_admin: admin)
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new('production'))

      described_class.setup

      expect_general_notification_events
    end
  end

  describe 'the notification tracker data migration' do
    it 'creates the General notification records when they are missing' do
      Admin.where(email: 'auto-admin@dummy.aaa').delete_all
      admin_count = Admin.count
      expected_admin = Admin.active.find_by(email: Settings::AdminEmail.downcase) || Admin.active.first
      hide_existing_general_protocols

      run_notification_protocol_migration

      expect_general_notification_events
      expect(Admin.count).to eq(admin_count)
      expect(Admin.find_by(email: 'auto-admin@dummy.aaa')).to be_nil

      protocol = Classification::Protocol.active.find_by!(name: 'General')
      notification = protocol.sub_processes.active.find_by!(name: 'Notification')
      records = [protocol, notification, *notification.protocol_events.active]
      expect(records.map(&:admin_id)).to all(eq(expected_admin.id))
    end

    it 'leaves existing General notification records unchanged' do
      protocol = Classification::Protocol.active.find_by(name: 'General') ||
                 Classification::Protocol.create!(name: 'General', current_admin: admin)
      protocol.update!(position: 9876, current_admin: admin)
      notification = protocol.sub_processes.active.find_by(name: 'Notification') ||
                     protocol.sub_processes.create!(name: 'Notification', current_admin: admin)
      events = %w[Sent Failed].map do |event_name|
        notification.protocol_events.active.find_by(name: event_name) ||
          notification.protocol_events.create!(name: event_name, current_admin: admin)
      end
      events.each do |event|
        event.update!(description: "Existing #{event.name} description", current_admin: admin)
      end
      existing_records = [protocol, notification, *events]
      original_attributes = existing_records.map { |record| record.reload.attributes }
      admin_count = Admin.count

      expect(Admin).not_to receive(:active)
      expect(Admin).not_to receive(:find_by)
      run_notification_protocol_migration

      expect(Admin.count).to eq(admin_count)
      expect(existing_records.map { |record| record.reload.attributes }).to eq(original_attributes)
      expect(Classification::Protocol.where(name: 'General').count).to eq(1)
      expect(Classification::Protocol.active.where(name: 'General').count).to eq(1)
      expect(protocol.sub_processes.active.where(name: 'Notification').count).to eq(1)
      expect(notification.protocol_events.active.where(name: %w[Sent Failed]).count).to eq(2)
    end
  end
end
