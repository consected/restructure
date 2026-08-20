# frozen_string_literal: true

# Tests for SaveTriggers::Exception - Issue #1365
#
# This spec verifies the exception save trigger, which can raise exceptions conditionally
# or re-raise original exceptions from within on_failure lifecycle hooks.

require 'rails_helper'

RSpec.describe SaveTriggers::Exception, type: :model do
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

    # Set up activity log definition
    al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

    ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
      oal.current_admin = @admin
      oal.disable!
    end

    config = <<~ENDDEF
      exception_trigger_test_1:
        label: Exception Trigger Test 1
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
    setup_access :activity_log__player_contact_phone__exception_trigger_test_1, resource_type: :activity_log_type,
                                                                                access: :create, user: @user
    al_def.add_master_association

    @al = @player_contact.activity_log__player_contact_phones.create!(
      select_call_direction: 'from player',
      select_who: 'test user',
      extra_log_type: 'exception_trigger_test_1'
    )

    @al.save_trigger_results = {}
    @al.trigger_variables = {}
  end

  describe 'basic assertion and configuration defaults' do
    it 'raises FphsException with a generic error message by default' do
      config = {}
      trigger = SaveTriggers::Exception.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, /An error occurred during save triggers/)
    end

    it 'raises FphsException with a custom message when message is specified' do
      config = { message: 'Custom save trigger failure' }
      trigger = SaveTriggers::Exception.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, 'Custom save trigger failure')
    end

    it 'performs substitutions in the message' do
      config = { message: 'Failed on item with direction {{select_call_direction}}' }
      trigger = SaveTriggers::Exception.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, 'Failed on item with direction from player')
    end

    it 'supports conditional execution via if' do
      # Evaluates to true, should raise
      config_true = {
        message: 'Conditional raise',
        if: { all: { this: { select_who: 'test user' } } }
      }
      trigger_true = SaveTriggers::Exception.new(config_true, @al)
      expect { trigger_true.perform }.to raise_error(FphsException, 'Conditional raise')

      # Evaluates to false, should NOT raise
      config_false = {
        message: 'Should not raise',
        if: { all: { this: { select_who: 'someone else' } } }
      }
      trigger_false = SaveTriggers::Exception.new(config_false, @al)
      expect { trigger_false.perform }.not_to raise_error
    end

    it 'supports status/condition-only configs with no message' do
      config_true = {
        if: { all: { this: { select_who: 'test user' } } }
      }
      trigger_true = SaveTriggers::Exception.new(config_true, @al)
      expect { trigger_true.perform }.to raise_error(FphsException, /An error occurred during save triggers/)

      config_false = {
        if: { all: { this: { select_who: 'someone else' } } }
      }
      trigger_false = SaveTriggers::Exception.new(config_false, @al)
      expect { trigger_false.perform }.not_to raise_error
    end

    it 'supports multiple configurations inside an Array' do
      config = [
        {
          message: 'First issue',
          if: { all: { this: { select_who: 'someone else' } } }
        },
        {
          message: 'Multiple configurations succeeded in raising',
          if: { all: { this: { select_who: 'test user' } } }
        }
      ]
      trigger = SaveTriggers::Exception.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, 'Multiple configurations succeeded in raising')
    end
  end

  describe 'original_failure option' do
    it 'raises an FphsException indicating no original exception exists if called outside an on_failure block' do
      # Ensure there is no active exception in Thread.current
      Thread.current[:active_save_trigger_exception] = nil

      config = { original_failure: true }
      trigger = SaveTriggers::Exception.new(config, @al)
      expect { trigger.perform }.to raise_error(FphsException, /no original exception to raise/)
    end

    it 're-raises the original exception when inside an on_failure context' do
      orig_e = ArgumentError.new('Original bad argument')
      Thread.current[:active_save_trigger_exception] = orig_e

      begin
        config = { original_failure: true }
        trigger = SaveTriggers::Exception.new(config, @al)
        expect { trigger.perform }.to raise_error(ArgumentError, 'Original bad argument')
      ensure
        Thread.current[:active_save_trigger_exception] = nil
      end
    end

    it 'raises FphsException incorporating the custom message and the original error message if both are specified' do
      orig_e = ArgumentError.new('Original bad argument')
      Thread.current[:active_save_trigger_exception] = orig_e

      begin
        config = {
          original_failure: true,
          message: 'Process halted'
        }
        trigger = SaveTriggers::Exception.new(config, @al)
        expect { trigger.perform }.to raise_error(FphsException, 'Process halted: Original bad argument')
      ensure
        Thread.current[:active_save_trigger_exception] = nil
      end
    end
  end

  describe 'ValidSaveTriggers registration' do
    it 'is included in ValidSaveTriggers' do
      expect(OptionConfigs::ExtraOptionImplementers::SaveTriggers::ValidSaveTriggers).to include(:exception)
    end

    it 'can be resolved via trigger_class' do
      klass = OptionConfigs::ExtraOptions.trigger_class(:exception)
      expect(klass).to eq(SaveTriggers::Exception)
    end
  end
end
