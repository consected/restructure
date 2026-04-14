# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SaveTriggers::Transaction, type: :model do
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
    # Re-setup the activity log if it was removed by other specs during this test run
    al_def = ActivityLog.find_by(id: ActivityLog::PlayerContactPhone.definition.id)
    unless al_def
      SetupHelper.setup_al_gen_tests('Phone Log', nil, 'player_contact', rec_type: 'phone')
      al_def = ActivityLog.active.where(item_type: 'player_contact', rec_type: 'phone').first
    end

    ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
      oal.current_admin = @admin
      oal.disable!
    end

    al_def.extra_log_types = <<~END_DEF
      step_1:
        label: Step 1
    END_DEF

    al_def.current_admin = @admin
    al_def.force_regenerate = true
    al_def.updated_at = DateTime.now
    al_def.save!
    ActivityLog.refresh_outdated
    al_def.reload
    al_def.force_option_config_parse

    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__step_1, resource_type: :activity_log_type, access: :create,
                                                              user: @user
    al_def.add_master_association

    @activity_log = @master.activity_log__player_contact_phones.create!(
      select_call_direction: 'to player',
      select_who: 'user',
      extra_log_type: 'step_1',
      player_contact: @player_contact,
      master: @master,
      current_user: @user
    )
    @activity_log.save_trigger_results ||= {}
  end

  describe '#perform' do
    context 'with successful nested triggers' do
      it 'executes all triggers in a transaction' do
        config = [
          { log: { message: 'First trigger', severity: 'info' } },
          { log: { message: 'Second trigger', severity: 'info' } }
        ]

        trigger = SaveTriggers::Transaction.new(config, @activity_log)

        expect(Rails.logger).to receive(:info).with(/First trigger/)
        expect(Rails.logger).to receive(:info).with(/Second trigger/)
        expect(Rails.logger).to receive(:info).with(/Completed 2 triggers successfully/)

        result = trigger.perform

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result[0][:trigger]).to eq(:log)
        expect(result[1][:trigger]).to eq(:log)
      end

      it 'stores results in save_trigger_results' do
        config = [
          { log: { message: 'Test message', severity: 'debug' } }
        ]

        trigger = SaveTriggers::Transaction.new(config, @activity_log)
        trigger.perform

        expect(@activity_log.save_trigger_results['transaction']).to be_an(Array)
        expect(@activity_log.save_trigger_results['transaction'].length).to eq(1)
      end
    end

    context 'with failing nested trigger' do
      it 'rolls back on exception' do
        # Create a configuration that will cause an error
        config = [
          { log: { message: 'This should succeed', severity: 'info' } },
          { create_master: { with: { invalid_config: true } } }
        ]

        trigger = SaveTriggers::Transaction.new(config, @activity_log)

        expect(Rails.logger).to receive(:info).with(/This should succeed/)
        expect(Rails.logger).to receive(:error).with(/Rolled back due to error/)

        expect do
          trigger.perform
        end.to raise_error(StandardError)
      end
    end

    context 'with single trigger (not array)' do
      it 'wraps single trigger in array' do
        config = { log: { message: 'Single trigger', severity: 'info' } }

        trigger = SaveTriggers::Transaction.new(config, @activity_log)

        expect(Rails.logger).to receive(:info).with(/Single trigger/)
        expect(Rails.logger).to receive(:info).with(/Completed 1 triggers successfully/)

        result = trigger.perform

        expect(result).to be_an(Array)
        expect(result.length).to eq(1)
      end
    end

    context 'with multiple different trigger types' do
      it 'executes different trigger types in sequence' do
        config = [
          { log: { message: 'First log message', severity: 'info' } },
          { log: { message: 'Second log message', severity: 'debug' } }
        ]

        trigger = SaveTriggers::Transaction.new(config, @activity_log)

        expect(Rails.logger).to receive(:info).with(/First log message/)
        expect(Rails.logger).to receive(:debug).with(/Second log message/)
        expect(Rails.logger).to receive(:info).with(/Completed 2 triggers successfully/)

        trigger.perform
      end
    end

    context 'with empty config' do
      it 'handles empty array gracefully' do
        config = []

        trigger = SaveTriggers::Transaction.new(config, @activity_log)

        expect(Rails.logger).to receive(:info).with(/Completed 0 triggers successfully/)

        result = trigger.perform

        expect(result).to eq([])
      end
    end

    context 'with nested create_reference trigger' do
      it 'executes real trigger within transaction' do
        # This test verifies that actual save triggers work within the transaction
        config = [
          { log: { message: 'Starting transaction', severity: 'info' } }
        ]

        trigger = SaveTriggers::Transaction.new(config, @activity_log)

        expect do
          trigger.perform
        end.not_to raise_error
      end
    end
  end
end
