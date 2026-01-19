# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SaveTriggers::RunBatchTrigger, type: :model do
  include ModelSupport
  include PlayerContactSupport

  describe 'running batch triggers from a save trigger' do
    before :each do
      create_user
      setup_access :player_contacts
      let_user_create_player_contacts
      create_item(data: rand(10_000_000_000_000_000), rank: 10)
      @player_contact.master.current_user = @user
      @master = @player_contact.master
      expect(@master).not_to be nil

      # Set up the activity log definition with batch_trigger configuration
      al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

      ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
        oal.current_admin = @admin
        oal.disable!
      end

      config = <<~ENDDEF
        run_batch_test_1:
          label: Run Batch Test 1
          fields:
            - select_call_direction
            - select_who

          batch_trigger:
            on_record:
              update_this:
                one:
                  force_not_editable_save: true
                  with:
                    select_who: 'batch processed'

        run_batch_caller:
          label: Run Batch Caller
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
      setup_access :activity_log__player_contact_phone__run_batch_test_1, resource_type: :activity_log_type,
                                                                          access: :create, user: @user
      setup_access :activity_log__player_contact_phone__run_batch_caller, resource_type: :activity_log_type,
                                                                          access: :create, user: @user
      al_def.add_master_association

      @al_def = al_def

      # Create some records for batch processing
      @al1 = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'original value 1',
        extra_log_type: 'run_batch_test_1'
      )
      @al2 = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'to player',
        select_who: 'original value 2',
        extra_log_type: 'run_batch_test_1'
      )

      # Create caller activity log
      @al_caller = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'caller',
        extra_log_type: 'run_batch_caller'
      )
    end

    describe 'foreground mode' do
      it 'runs the batch trigger synchronously and returns results' do
        resource_name = :activity_log__player_contact_phones

        config = {
          resource_name: resource_name.to_s,
          mode: 'foreground'
        }

        trigger = SaveTriggers::RunBatchTrigger.new(config, @al_caller)
        result = trigger.perform

        expect(result).to be_an(Array)
        expect(result.first[:resource_name]).to eq resource_name.to_s
        expect(result.first[:mode]).to eq 'foreground'
        expect(result.first[:status]).to eq 'completed'
        expect(result.first[:processed_ids]).to include(@al1.id, @al2.id)

        # Verify batch trigger was actually run
        @al1.reload
        @al2.reload
        expect(@al1.select_who).to eq 'batch processed'
        expect(@al2.select_who).to eq 'batch processed'
      end

      it 'respects the limit parameter' do
        resource_name = :activity_log__player_contact_phones

        config = {
          resource_name: resource_name.to_s,
          mode: 'foreground',
          limit: 1
        }

        trigger = SaveTriggers::RunBatchTrigger.new(config, @al_caller)
        result = trigger.perform

        expect(result.first[:processed_ids].length).to eq 1
      end
    end

    describe 'background mode' do
      it 'queues the batch trigger as a job' do
        resource_name = :activity_log__player_contact_phones

        config = {
          resource_name: resource_name.to_s,
          mode: 'background'
        }

        expect(HandleBatchJob).to receive(:perform_later).with(
          'ActivityLog::PlayerContactPhone',
          hash_including(limit: nil)
        )

        trigger = SaveTriggers::RunBatchTrigger.new(config, @al_caller)
        result = trigger.perform

        expect(result.first[:status]).to eq 'queued'
      end
    end

    describe 'conditional execution' do
      it 'runs when if condition is met' do
        resource_name = :activity_log__player_contact_phones

        config = {
          resource_name: resource_name.to_s,
          mode: 'foreground',
          if: {
            all: {
              this: {
                select_call_direction: 'from player'
              }
            }
          }
        }

        trigger = SaveTriggers::RunBatchTrigger.new(config, @al_caller)
        result = trigger.perform

        expect(result).not_to be_empty
        expect(result.first[:status]).to eq 'completed'
      end

      it 'skips when if condition is not met' do
        resource_name = :activity_log__player_contact_phones

        config = {
          resource_name: resource_name.to_s,
          mode: 'foreground',
          if: {
            all: {
              this: {
                select_call_direction: 'nonexistent value'
              }
            }
          }
        }

        trigger = SaveTriggers::RunBatchTrigger.new(config, @al_caller)
        result = trigger.perform

        expect(result).to be_empty
      end
    end

    describe 'error handling' do
      it 'raises an error when resource_name is missing' do
        config = {
          mode: 'foreground'
        }

        trigger = SaveTriggers::RunBatchTrigger.new(config, @al_caller)
        expect { trigger.perform }.to raise_error(FphsException, /resource_name to be specified/)
      end

      it 'raises an error when resource is not found' do
        config = {
          resource_name: 'nonexistent_resource',
          mode: 'foreground'
        }

        trigger = SaveTriggers::RunBatchTrigger.new(config, @al_caller)
        expect { trigger.perform }.to raise_error(FphsException, /could not find resource/)
      end

      it 'raises an error for invalid mode' do
        resource_name = :activity_log__player_contact_phones

        config = {
          resource_name: resource_name.to_s,
          mode: 'invalid'
        }

        trigger = SaveTriggers::RunBatchTrigger.new(config, @al_caller)
        expect { trigger.perform }.to raise_error(FphsException, /mode must be/)
      end
    end

    describe 'save_trigger_results' do
      it 'stores results in save_trigger_results' do
        @al_caller.save_trigger_results = {}
        resource_name = :activity_log__player_contact_phones

        config = {
          resource_name: resource_name.to_s,
          mode: 'foreground'
        }

        trigger = SaveTriggers::RunBatchTrigger.new(config, @al_caller)
        trigger.perform

        expect(@al_caller.save_trigger_results['run_batch_trigger']).to be_an(Array)
        expect(@al_caller.save_trigger_results['run_batch_trigger'].first[:resource_name]).to eq resource_name.to_s
      end
    end

    describe 'multiple batch triggers' do
      it 'processes multiple configurations' do
        resource_name = :activity_log__player_contact_phones

        config = [
          { resource_name: resource_name.to_s, mode: 'foreground' }
        ]

        trigger = SaveTriggers::RunBatchTrigger.new(config, @al_caller)
        result = trigger.perform

        expect(result.length).to eq 1
      end
    end

    describe 'named configuration format' do
      it 'handles named configuration format' do
        resource_name = :activity_log__player_contact_phones

        config = {
          batch_1: {
            resource_name: resource_name.to_s,
            mode: 'foreground'
          }
        }

        trigger = SaveTriggers::RunBatchTrigger.new(config, @al_caller)
        result = trigger.perform

        expect(result).not_to be_empty
        expect(result.first[:status]).to eq 'completed'
      end
    end
  end
end
