# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SaveTriggers::Log, type: :model do
  include ModelSupport
  include PlayerContactSupport

  before :each do
    create_user
    setup_access :player_contacts
    let_user_create_player_contacts
    create_item(data: rand(10_000_000_000_000_000), rank: 10)
    @player_contact.master.current_user = @user
    @master = @player_contact.master
    expect(@master).not_to be nil

    # Set up activity log definition with save_trigger_results support
    al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

    ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
      oal.current_admin = @admin
      oal.disable!
    end

    config = <<~ENDDEF
      log_test_1:
        label: Log Test 1
        fields:
          - select_call_direction
          - select_who
    ENDDEF

    al_def.extra_log_types = config
    al_def.current_admin = @admin
    al_def.force_regenerate = true
    al_def.updated_at = DateTime.now
    al_def.save!
    ActivityLog.refresh_outdated
    al_def.reload
    al_def.force_option_config_parse

    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__log_test_1, resource_type: :activity_log_type,
                                                                  access: :create, user: @user
    al_def.add_master_association

    @al = @player_contact.activity_log__player_contact_phones.create!(
      select_call_direction: 'from player',
      select_who: 'test user',
      extra_log_type: 'log_test_1'
    )
  end

  describe 'basic log functionality' do
    it 'logs a message at info level by default' do
      config = {
        message: 'Test log message'
      }

      expect(Rails.logger).to receive(:info).with(/\[SaveTrigger::Log\].*Test log message/)

      trigger = SaveTriggers::Log.new(config, @al)
      result = trigger.perform

      expect(result).to be_an(Array)
      expect(result.first[:message]).to eq 'Test log message'
      expect(result.first[:severity]).to eq 'info'
      expect(result.first[:logged_at]).to be_a(Time)
    end

    it 'logs at debug severity' do
      config = {
        message: 'Debug message',
        severity: 'debug'
      }

      expect(Rails.logger).to receive(:debug).with(/\[SaveTrigger::Log\].*Debug message/)

      trigger = SaveTriggers::Log.new(config, @al)
      result = trigger.perform

      expect(result.first[:severity]).to eq 'debug'
    end

    it 'logs at warn severity' do
      config = {
        message: 'Warning message',
        severity: 'warn'
      }

      expect(Rails.logger).to receive(:warn).with(/\[SaveTrigger::Log\].*Warning message/)

      trigger = SaveTriggers::Log.new(config, @al)
      result = trigger.perform

      expect(result.first[:severity]).to eq 'warn'
    end

    it 'logs at error severity' do
      config = {
        message: 'Error message',
        severity: 'error'
      }

      expect(Rails.logger).to receive(:error).with(/\[SaveTrigger::Log\].*Error message/)

      trigger = SaveTriggers::Log.new(config, @al)
      result = trigger.perform

      expect(result.first[:severity]).to eq 'error'
    end
  end

  describe 'message substitutions' do
    it 'substitutes item attributes in message' do
      config = {
        message: 'Processing activity log {{id}} for master {{master_id}}'
      }

      expected_message = "Processing activity log #{@al.id} for master #{@al.master_id}"
      expect(Rails.logger).to receive(:info).with(/#{Regexp.escape(expected_message)}/)

      trigger = SaveTriggers::Log.new(config, @al)
      result = trigger.perform

      expect(result.first[:message]).to eq expected_message
    end

    it 'handles missing attributes gracefully' do
      config = {
        message: 'Value: {{nonexistent_field}}'
      }

      # Should not raise an error, should log with missing value
      expect(Rails.logger).to receive(:info).with(/\[SaveTrigger::Log\]/)

      trigger = SaveTriggers::Log.new(config, @al)
      expect { trigger.perform }.not_to raise_error
    end
  end

  describe 'conditional logging' do
    it 'logs when if condition is met' do
      config = {
        message: 'Condition met',
        if: {
          all: {
            this: {
              select_call_direction: 'from player'
            }
          }
        }
      }

      expect(Rails.logger).to receive(:info).with(/Condition met/)

      trigger = SaveTriggers::Log.new(config, @al)
      trigger.perform
    end

    it 'skips logging when if condition is not met' do
      config = {
        message: 'Condition not met',
        if: {
          all: {
            this: {
              select_call_direction: 'nonexistent value'
            }
          }
        }
      }

      expect(Rails.logger).not_to receive(:info).with(/Condition not met/)

      trigger = SaveTriggers::Log.new(config, @al)
      result = trigger.perform

      expect(result).to be_empty
    end
  end

  describe 'multiple log entries' do
    it 'processes multiple log configurations' do
      config = [
        { message: 'First log', severity: 'info' },
        { message: 'Second log', severity: 'warn' }
      ]

      expect(Rails.logger).to receive(:info).with(/First log/)
      expect(Rails.logger).to receive(:warn).with(/Second log/)

      trigger = SaveTriggers::Log.new(config, @al)
      result = trigger.perform

      expect(result.length).to eq 2
      expect(result[0][:message]).to eq 'First log'
      expect(result[1][:message]).to eq 'Second log'
    end
  end

  describe 'error handling' do
    it 'raises an error when message is missing' do
      config = {
        severity: 'info'
      }

      trigger = SaveTriggers::Log.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, /message to be specified/)
    end

    it 'raises an error for invalid severity' do
      config = {
        message: 'Test',
        severity: 'invalid'
      }

      trigger = SaveTriggers::Log.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, /severity must be one of/)
    end
  end

  describe 'save_trigger_results' do
    it 'stores results in save_trigger_results' do
      @al.save_trigger_results = {}
      config = {
        message: 'Test message'
      }

      allow(Rails.logger).to receive(:info)

      trigger = SaveTriggers::Log.new(config, @al)
      trigger.perform

      expect(@al.save_trigger_results['log']).to be_an(Array)
      expect(@al.save_trigger_results['log'].first[:message]).to eq 'Test message'
    end
  end
end
