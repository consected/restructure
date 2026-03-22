# frozen_string_literal: true

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

    context 'job execution' do
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
