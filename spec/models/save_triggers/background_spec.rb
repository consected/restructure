# frozen_string_literal: true

# Tests background trigger-list composition, including the each iterator.
require 'rails_helper'

RSpec.describe SaveTriggers::Background, type: :model do
  include ModelSupport
  include PlayerContactSupport
  include ActiveJob::TestHelper

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  before_all do
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
    context 'with valid trigger configuration' do
      it 'queues a background job' do
        config = [
          { log: { message: 'Background trigger 1', severity: 'info' } },
          { log: { message: 'Background trigger 2', severity: 'debug' } }
        ]

        trigger = SaveTriggers::Background.new(config, @activity_log)

        expect do
          trigger.perform
        end.to have_enqueued_job(SaveTriggersBackgroundJob)
      end

      it 'returns queue result with proper structure' do
        config = [
          { log: { message: 'Test message', severity: 'info' } }
        ]

        trigger = SaveTriggers::Background.new(config, @activity_log)
        result = trigger.perform

        expect(result[:status]).to eq('queued')
        expect(result[:item_class]).to eq(@activity_log.class.name)
        expect(result[:item_id]).to eq(@activity_log.id)
        expect(result[:trigger_count]).to eq(1)
        expect(result[:queued_at]).to be_a(Time)
      end

      it 'stores result in save_trigger_results' do
        config = [
          { log: { message: 'Test', severity: 'info' } }
        ]

        trigger = SaveTriggers::Background.new(config, @activity_log)
        trigger.perform

        expect(@activity_log.save_trigger_results['background']).to be_a(Hash)
        expect(@activity_log.save_trigger_results['background'][:status]).to eq('queued')
      end

      it 'passes correct parameters to the job' do
        config = [
          { log: { message: 'Job parameter test', severity: 'info' } }
        ]

        trigger = SaveTriggers::Background.new(config, @activity_log)

        expect do
          trigger.perform
        end.to have_enqueued_job(SaveTriggersBackgroundJob).with(
          item_class: @activity_log.class.name,
          item_id: @activity_log.id,
          user_id: @user.id,
          triggers: config.as_json
        )
      end
    end

    context 'with single trigger (not array)' do
      it 'wraps single trigger in array' do
        config = { log: { message: 'Single trigger', severity: 'info' } }

        trigger = SaveTriggers::Background.new(config, @activity_log)
        result = trigger.perform

        expect(result[:trigger_count]).to eq(1)
      end
    end

    context 'with empty config' do
      it 'handles empty array gracefully' do
        config = []

        trigger = SaveTriggers::Background.new(config, @activity_log)
        result = trigger.perform

        expect(result[:trigger_count]).to eq(0)
      end
    end

    context 'with selected background context' do
      it 'resolves selected values in the foreground and exposes them in the job' do
        @activity_log.save_trigger_results['selected_value'] = 'from foreground'
        @activity_log.trigger_variables = { selected_variable: 'from trigger variables' }
        config = {
          with: {
            selected_value: '{{save_trigger_results.selected_value}}',
            selected_variable: '{{variables.selected_variable}}'
          },
          do: [{ log: {
            message: 'Context {{background_context.selected_value}} / {{background_context.selected_variable}}',
            severity: 'info'
          } }]
        }

        trigger = SaveTriggers::Background.new(config, @activity_log)
        expect { trigger.perform }.to have_enqueued_job(SaveTriggersBackgroundJob).with(
          hash_including(context: { selected_value: 'from foreground', selected_variable: 'from trigger variables' })
        )
        expect(@activity_log.save_trigger_results['background'][:context_keys]).to eq(%i[selected_value selected_variable])
        expect(Rails.logger).to receive(:info).with(%r{Context from foreground / from trigger variables})
        allow(Rails.logger).to receive(:info)

        perform_enqueued_jobs
      end

      it 'serializes nested values, dates, times, and records, applying the job user to nested records' do
        @activity_log.save_trigger_results['selected_payload'] = {
          label: 'selected',
          date: Date.current,
          time: Time.utc(2025, 1, 2, 3, 4, 5),
          records: [@player_contact]
        }
        @activity_log.save_trigger_results['top_level_record'] = @player_contact
        config = {
          with: {
            payload: { object: '{{{save_trigger_results.selected_payload}}}' },
            record: '{{{save_trigger_results.top_level_record}}}'
          },
          do: [{ log: { message: 'Inspect context', severity: 'info' } }]
        }
        allow_any_instance_of(SaveTriggers::Log).to receive(:perform) do |log_trigger|
          payload = log_trigger.item.background_context[:payload]
          expect(payload[:label]).to eq('selected')
          expect(payload[:date]).to eq(Date.current)
          expect(payload[:time]).to eq(Time.utc(2025, 1, 2, 3, 4, 5))
          expect(payload[:records].first.id).to eq(@player_contact.id)
          expect(payload[:records].first.current_user).to eq(@user)
          expect(log_trigger.item.background_context[:record].current_user).to eq(@user)
          raw_payload = Formatter::Substitution.substitute_plain(
            '{{{background_context.payload}}}', data: log_trigger.item
          )
          expect(raw_payload).to eq(payload)
          label = Formatter::Substitution.substitute(
            '{{background_context.payload.label}}', data: log_trigger.item
          )
          expect(label).to eq('selected')
        end

        SaveTriggers::Background.new(config, @activity_log).perform
        perform_enqueued_jobs
      end

      it 'rejects missing strict substitutions and preserves ignored and raw missing values' do
        strict_config = {
          with: { missing: '{{not_present}}' },
          do: [{ log: { message: 'Missing value' } }]
        }
        expect { SaveTriggers::Background.new(strict_config, @activity_log).perform }
          .to raise_error(FphsException)

        config = {
          with: { ignored: '{{not_present::ignore_missing}}', raw: '{{{not_present}}}' },
          do: [{ log: { message: 'Missing values' } }]
        }
        allow_any_instance_of(SaveTriggers::Log).to receive(:perform) do |log_trigger|
          expect(log_trigger.item.background_context).to eq(ignored: '', raw: nil)
        end

        SaveTriggers::Background.new(config, @activity_log).perform
        perform_enqueued_jobs
      end

      it 'queues a distinct resolved context for each each iteration' do
        config = [{
          each: {
            iterator_name: 'loop_result',
            value: %w[first second],
            do: [{
              background: {
                with: { value: '{{save_trigger_results.loop_result_value}}' },
                do: [{ log: { message: 'Iteration {{background_context.value}}', severity: 'info' } }]
              }
            }]
          }
        }]
        trigger = SaveTriggers::Each.new(config.first[:each], @activity_log)

        expect { trigger.perform }.to have_enqueued_job(SaveTriggersBackgroundJob).twice
        expect(Rails.logger).to receive(:info).with(/Iteration first/)
        expect(Rails.logger).to receive(:info).with(/Iteration second/)
        allow(Rails.logger).to receive(:info)

        perform_enqueued_jobs
      end

      it 'rejects a context form without do and non-serializable selected values' do
        expect do
          SaveTriggers::Background.new({ with: { selected: 'value' } }, @activity_log).perform
        end.to raise_error(FphsException, /do/)

        expect do
          SaveTriggers::Background.new(
            { with: ['invalid'], do: [{ log: { message: 'Never queued' } }] }, @activity_log
          ).perform
        end.to raise_error(FphsException, /with.*Hash/)

        @activity_log.save_trigger_results['unserializable'] = Object.new
        config = {
          with: { selected: '{{{save_trigger_results.unserializable}}}' },
          do: [{ log: { message: 'Never queued' } }]
        }
        expect do
          SaveTriggers::Background.new(config, @activity_log).perform
        end.to raise_error(FphsException, /selected/)

        @activity_log.save_trigger_results['unserializable'] = { 1 => 'unsupported key' }
        expect do
          SaveTriggers::Background.new(config, @activity_log).perform
        end.to raise_error(FphsException, /selected/)

        @activity_log.save_trigger_results['unserializable'] = @activity_log.class.where(id: @activity_log.id)
        expect do
          SaveTriggers::Background.new(config, @activity_log).perform
        end.to raise_error(FphsException, /selected/)
      end

      it 'refuses to queue a context form whose do is not a trigger list' do
        expect do
          SaveTriggers::Background.new({ with: { selected: 'value' }, do: 'not a list' }, @activity_log).perform
        end.to raise_error(FphsException, /do must be a trigger list/)
        expect(SaveTriggersBackgroundJob).not_to have_been_enqueued
      end

      it 'refuses to queue a with/do context hash wrapped in a list' do
        config = [{ with: { selected: 'value' }, do: [{ log: { message: 'Never queued' } }] }]

        expect do
          SaveTriggers::Background.new(config, @activity_log).perform
        end.to raise_error(FphsException, /only valid inside a background trigger hash/)
        expect(SaveTriggersBackgroundJob).not_to have_been_enqueued
      end

      it 'enforces the configured serialized context size limit' do
        stub_const('Settings::SaveTriggerBackgroundContextMaxBytes', 1)
        config = { with: { selected: 'too large' }, do: [{ log: { message: 'Never queued' } }] }

        expect do
          SaveTriggers::Background.new(config, @activity_log).perform
        end.to raise_error(FphsException, /size|bytes/i)
      end
    end

    context 'job execution' do
      it 'does not queue on_complete from a plain hash form as a trigger' do
        config = { log: { message: 'Plain', severity: 'info' }, on_complete: { log: { message: 'Done', severity: 'info' } } }

        SaveTriggers::Background.new(config, @activity_log).perform
        expect { perform_enqueued_jobs }.not_to raise_error
      end

      it 'executes triggers when job runs' do
        config = [
          { log: { message: 'Background execution test', severity: 'info' } }
        ]

        trigger = SaveTriggers::Background.new(config, @activity_log)
        trigger.perform

        # Now run the job and verify triggers execute
        expect(Rails.logger).to receive(:info).with(/Background execution test/).at_least(:once)
        allow(Rails.logger).to receive(:info)

        perform_enqueued_jobs
      end

      it 'preserves user context in background job' do
        config = [
          { log: { message: 'User context test', severity: 'info' } }
        ]

        trigger = SaveTriggers::Background.new(config, @activity_log)
        trigger.perform

        # The job should be queued with the user_id
        expect do
          perform_enqueued_jobs
        end.not_to raise_error
      end

      it 'executes each within a background trigger list and its lifecycle callback' do
        config = [
          {
            each: {
              value: %w[first second],
              do: [
                {
                  log: {
                    message: 'Background {{save_trigger_results.iterator_index}} => {{save_trigger_results.iterator_value}}',
                    severity: 'info',
                    on_complete: [
                      {
                        log: {
                          message: 'Background callback {{save_trigger_results.iterator_index}} => {{save_trigger_results.iterator_value}}',
                          severity: 'info'
                        }
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]

        trigger = SaveTriggers::Background.new(config, @activity_log)
        trigger.perform

        expect(Rails.logger).to receive(:info).with(/Background 0 => first/)
        expect(Rails.logger).to receive(:info).with(/Background callback 0 => first/)
        expect(Rails.logger).to receive(:info).with(/Background 1 => second/)
        expect(Rails.logger).to receive(:info).with(/Background callback 1 => second/)
        allow(Rails.logger).to receive(:info)

        expect { perform_enqueued_jobs }.not_to raise_error
      end
    end
  end
end

RSpec.describe SaveTriggersBackgroundJob, type: :job do
  include ModelSupport
  include PlayerContactSupport
  include ActiveJob::TestHelper

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
    ActiveJob::Base.queue_adapter = original_adapter
  end

  before_all do
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
    it 'executes the specified triggers' do
      triggers = [
        { 'log' => { 'message' => 'Job test message', 'severity' => 'info' } }
      ]

      expect(Rails.logger).to receive(:info).with(/Job test message/)
      allow(Rails.logger).to receive(:info)

      SaveTriggersBackgroundJob.perform_now(
        item_class: @activity_log.class.name,
        item_id: @activity_log.id,
        user_id: @user.id,
        triggers:
      )
    end

    it 'handles multiple triggers' do
      triggers = [
        { 'log' => { 'message' => 'First job message', 'severity' => 'info' } },
        { 'log' => { 'message' => 'Second job message', 'severity' => 'debug' } }
      ]

      expect(Rails.logger).to receive(:info).with(/First job message/)
      expect(Rails.logger).to receive(:debug).with(/Second job message/)
      allow(Rails.logger).to receive(:info)

      result = SaveTriggersBackgroundJob.perform_now(
        item_class: @activity_log.class.name,
        item_id: @activity_log.id,
        user_id: @user.id,
        triggers:
      )

      expect(result.length).to eq(2)
    end

    it 'sets current_user on the item' do
      triggers = [
        { 'log' => { 'message' => 'User test', 'severity' => 'info' } }
      ]

      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:debug)

      # This should not raise an error about missing user
      expect do
        SaveTriggersBackgroundJob.perform_now(
          item_class: @activity_log.class.name,
          item_id: @activity_log.id,
          user_id: @user.id,
          triggers:
        )
      end.not_to raise_error
    end

    it 'raises error when nil user_id is passed' do
      triggers = [
        { 'log' => { 'message' => 'No user test', 'severity' => 'info' } }
      ]

      allow(Rails.logger).to receive(:info)
      allow(Rails.logger).to receive(:debug)

      # Save triggers require a current_user to be set - this should raise an error
      expect do
        SaveTriggersBackgroundJob.perform_now(
          item_class: @activity_log.class.name,
          item_id: @activity_log.id,
          user_id: nil,
          triggers:
        )
      end.to raise_error(FphsException, /save_trigger item current user not set/)
    end
  end
end
