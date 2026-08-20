# frozen_string_literal: true

# Tests for on_complete and on_failure lifecycle hooks on save triggers.
# These hooks are implemented in SaveTriggersBase and automatically available
# to all trigger types. on_complete fires after a successful perform,
# on_failure fires when perform raises an exception.
#
# Two levels of hooks are supported:
# - Top-level: extracted in initialize via extract_lifecycle_hooks, fired by perform_with_lifecycle
# - Per-entry: extracted inside each named entry via with_entry_lifecycle in the trigger's perform loop
#
# See GitHub Issue #982.
require 'rails_helper'

RSpec.describe 'SaveTrigger lifecycle hooks (on_complete / on_failure)', type: :model do
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
      lifecycle_test_1:
        label: Lifecycle Test 1
        fields:
          - select_call_direction
          - select_who
          - notes
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
    setup_access :activity_log__player_contact_phone__lifecycle_test_1, resource_type: :activity_log_type,
                                                                        access: :create, user: @user
    al_def.add_master_association

    @activity_log = @player_contact.activity_log__player_contact_phones.create!(
      select_call_direction: 'from player',
      select_who: 'test user',
      extra_log_type: 'lifecycle_test_1'
    )
    @activity_log.save_trigger_results ||= {}
  end

  describe 'on_complete' do
    it 'fires on_complete triggers after a successful perform' do
      config = {
        message: 'Main trigger message',
        severity: 'info',
        on_complete: [
          { log: { message: 'Completion hook fired', severity: 'info' } }
        ]
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)

      # The main trigger should log the main message
      expect(Rails.logger).to receive(:info).with(/Main trigger message/).ordered
      # The on_complete trigger should fire after the main trigger
      expect(Rails.logger).to receive(:info).with(/Completion hook fired/).ordered

      trigger.perform_with_lifecycle
    end

    it 'passes results to on_complete triggers via save_trigger_results' do
      config = {
        message: 'Record processed',
        severity: 'info',
        on_complete: [
          { log: { message: 'on_complete ran after log trigger', severity: 'info' } }
        ]
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)
      trigger.perform_with_lifecycle

      # The main trigger should have completed and stored results
      expect(@activity_log.save_trigger_results['log']).to be_present
    end

    it 'supports on_complete with multiple triggers' do
      config = {
        message: 'Main log',
        severity: 'info',
        on_complete: [
          { log: { message: 'First completion trigger', severity: 'info' } },
          { log: { message: 'Second completion trigger', severity: 'warn' } }
        ]
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)

      expect(Rails.logger).to receive(:info).with(/Main log/).ordered
      expect(Rails.logger).to receive(:info).with(/First completion trigger/).ordered
      expect(Rails.logger).to receive(:warn).with(/Second completion trigger/).ordered

      trigger.perform_with_lifecycle
    end

    it 'does not fire on_complete when perform raises an exception' do
      # Use an invalid config that will cause the log trigger to fail
      config = {
        message: nil,
        severity: 'info',
        on_complete: [
          { log: { message: 'Should NOT fire', severity: 'info' } }
        ]
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)

      # on_complete should NOT be called
      expect(Rails.logger).not_to receive(:info).with(/Should NOT fire/)

      expect { trigger.perform_with_lifecycle }.to raise_error(FphsException)
    end

    it 'supports on_complete as a hash (single trigger)' do
      config = {
        message: 'Main message',
        severity: 'info',
        on_complete: {
          log: { message: 'Single completion trigger', severity: 'info' }
        }
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)

      expect(Rails.logger).to receive(:info).with(/Main message/).ordered
      expect(Rails.logger).to receive(:info).with(/Single completion trigger/).ordered

      trigger.perform_with_lifecycle
    end
  end

  describe 'on_failure' do
    it 'fires on_failure triggers when perform raises an exception and does not re-raise by default' do
      # message: nil will cause log trigger to raise FphsException
      config = {
        message: nil,
        severity: 'info',
        on_failure: [
          { log: { message: 'Failure hook fired', severity: 'error' } }
        ]
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)

      expect(Rails.logger).to receive(:error).with(/Failure hook fired/)

      expect { trigger.perform_with_lifecycle }.not_to raise_error
    end

    it 're-raises the original exception after on_failure triggers execute if exception original_failure is configured' do
      config = {
        message: nil,
        severity: 'info',
        on_failure: [
          { log: { message: 'Failure logged', severity: 'error' } },
          { exception: { original_failure: true } }
        ]
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)

      expect { trigger.perform_with_lifecycle }.to raise_error(FphsException, /log save trigger requires message/)
    end

    it 'does not fire on_failure when perform succeeds' do
      config = {
        message: 'Successful trigger',
        severity: 'info',
        on_failure: [
          { log: { message: 'Should NOT fire on success', severity: 'error' } }
        ]
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)

      expect(Rails.logger).not_to receive(:error).with(/Should NOT fire on success/)

      trigger.perform_with_lifecycle
    end

    it 'supports on_failure as a hash (single trigger) and does not re-raise' do
      config = {
        message: nil,
        severity: 'info',
        on_failure: {
          log: { message: 'Single failure trigger', severity: 'error' }
        }
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)

      expect(Rails.logger).to receive(:error).with(/Single failure trigger/)

      expect { trigger.perform_with_lifecycle }.not_to raise_error
    end
  end

  describe 'on_complete and on_failure together' do
    it 'fires only on_complete on success when both are configured' do
      config = {
        message: 'Main trigger',
        severity: 'info',
        on_complete: [
          { log: { message: 'Completion fired', severity: 'info' } }
        ],
        on_failure: [
          { log: { message: 'Failure should not fire', severity: 'error' } }
        ]
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)

      expect(Rails.logger).to receive(:info).with(/Main trigger/).ordered
      expect(Rails.logger).to receive(:info).with(/Completion fired/).ordered
      expect(Rails.logger).not_to receive(:error).with(/Failure should not fire/)

      trigger.perform_with_lifecycle
    end

    it 'fires only on_failure on exception when both are configured and does not raise' do
      config = {
        message: nil,
        severity: 'info',
        on_complete: [
          { log: { message: 'Complete should not fire', severity: 'info' } }
        ],
        on_failure: [
          { log: { message: 'Failure fired', severity: 'error' } }
        ]
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)

      expect(Rails.logger).not_to receive(:info).with(/Complete should not fire/)
      expect(Rails.logger).to receive(:error).with(/Failure fired/)

      expect { trigger.perform_with_lifecycle }.not_to raise_error
    end
  end

  describe 'lifecycle hooks via calc_triggers dispatch' do
    it 'automatically fires on_complete when triggers are dispatched via calc_triggers' do
      configs = {
        log: {
          message: 'Dispatched trigger',
          severity: 'info',
          on_complete: [
            { log: { message: 'Dispatched completion', severity: 'info' } }
          ]
        }
      }

      expect(Rails.logger).to receive(:info).with(/Dispatched trigger/).ordered
      expect(Rails.logger).to receive(:info).with(/Dispatched completion/).ordered

      OptionConfigs::ExtraOptions.calc_triggers(@activity_log, configs)
    end

    it 'automatically fires on_failure when triggers dispatched via calc_triggers fail and does not raise' do
      configs = {
        log: {
          message: nil,
          severity: 'info',
          on_failure: [
            { log: { message: 'Dispatched failure hook', severity: 'error' } }
          ]
        }
      }

      expect(Rails.logger).to receive(:error).with(/Dispatched failure hook/)

      expect { OptionConfigs::ExtraOptions.calc_triggers(@activity_log, configs) }.not_to raise_error
    end
  end

  describe 'lifecycle hooks on other trigger types' do
    it 'fires on_complete for update_this trigger' do
      # on_complete is placed at the top level of the trigger config,
      # alongside the named entries that update_this iterates over
      config = {
        one: {
          with: {
            select_who: 'lifecycle updated'
          }
        },
        on_complete: [
          { log: { message: 'update_this completed', severity: 'info' } }
        ]
      }

      trigger = SaveTriggers::UpdateThis.new(config, @activity_log)

      expect(Rails.logger).to receive(:info).with(/update_this completed/)
      allow(Rails.logger).to receive(:info)

      trigger.perform_with_lifecycle
      expect(@activity_log.select_who).to eq 'lifecycle updated'
    end

    it 'fires on_complete for a trigger dispatched via calc_triggers with multiple trigger types' do
      setup_access :player_contacts, resource_type: :table, access: :create, user: @user

      log_configs = {
        log: {
          message: 'calc_triggers dispatch test',
          severity: 'info',
          on_complete: [
            { log: { message: 'dispatch on_complete fired', severity: 'info' } }
          ]
        }
      }

      expect(Rails.logger).to receive(:info).with(/calc_triggers dispatch test/)
      expect(Rails.logger).to receive(:info).with(/dispatch on_complete fired/)
      allow(Rails.logger).to receive(:info)

      OptionConfigs::ExtraOptions.calc_triggers(@activity_log, log_configs)
    end
  end

  describe 'lifecycle hooks extract on_complete/on_failure from config' do
    it 'removes on_complete from Hash config before trigger processes it' do
      config = {
        message: 'Test extraction',
        severity: 'info',
        on_complete: [
          { log: { message: 'Extracted hook', severity: 'info' } }
        ]
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)

      # normalize_trigger_config creates an owned deep copy; on_complete is
      # extracted from that copy so the trigger's working config never sees it
      expect(trigger.config).not_to have_key(:on_complete)
    end

    it 'removes on_failure from Hash config before trigger processes it' do
      config = {
        message: 'Test extraction',
        severity: 'info',
        on_failure: [
          { log: { message: 'Extracted hook', severity: 'error' } }
        ]
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)

      expect(trigger.config).not_to have_key(:on_failure)
    end

    it 'does not modify Array configs, preserving per-entry on_complete' do
      # Array configs (used by Notify) are not modified
      config = [
        {
          type: 'email',
          on_complete: { update_this: { one: { with: { notes: 'done' } } } }
        }
      ]

      SaveTriggers::Log.new(config, @activity_log)

      # Per-entry on_complete should be preserved
      expect(config.first).to have_key(:on_complete)
    end
  end

  describe 'lifecycle hooks in nested trigger structures' do
    it 'fires on_complete for triggers inside execute_trigger_list' do
      # Transaction trigger uses execute_trigger_list internally
      config = [
        {
          log: {
            message: 'Nested trigger',
            severity: 'info',
            on_complete: [
              { log: { message: 'Nested on_complete', severity: 'info' } }
            ]
          }
        }
      ]

      trigger = SaveTriggers::Transaction.new(config, @activity_log)

      # We can't use ordered expectations here because the Transaction trigger
      # also logs its own completion message. Instead verify both messages are logged.
      expect(Rails.logger).to receive(:info).with(/Nested trigger/)
      expect(Rails.logger).to receive(:info).with(/Nested on_complete/)
      allow(Rails.logger).to receive(:info)

      trigger.perform
    end
  end

  describe 'per-entry lifecycle hooks (with_entry_lifecycle)' do
    it 'fires per-entry on_complete for add_tracker-style named entries' do
      # Simulate a Pattern B trigger with named entries, each having
      # its own on_complete. UpdateThis uses the same pattern.
      config = {
        one: {
          with: {
            select_who: 'entry lifecycle test'
          },
          on_complete: [
            { log: { message: 'Entry one completed', severity: 'info' } }
          ]
        }
      }

      trigger = SaveTriggers::UpdateThis.new(config, @activity_log)

      expect(Rails.logger).to receive(:info).with(/Entry one completed/)
      allow(Rails.logger).to receive(:info)

      trigger.perform_with_lifecycle
      expect(@activity_log.select_who).to eq 'entry lifecycle test'
    end

    it 'fires per-entry on_failure for named entries when processing raises and does not raise' do
      # Use log with nil message to trigger a FphsException
      log_config = {
        message: nil,
        severity: 'info',
        on_failure: [
          { log: { message: 'Per-entry failure hook', severity: 'error' } }
        ]
      }

      trigger = SaveTriggers::Log.new(log_config, @activity_log)

      expect(Rails.logger).to receive(:error).with(/Per-entry failure hook/)

      expect { trigger.perform_with_lifecycle }.not_to raise_error
    end

    it 'fires per-entry on_complete for each entry in a multi-entry log trigger' do
      config = [
        {
          message: 'Log entry one',
          severity: 'info',
          on_complete: [
            { log: { message: 'Entry one hook', severity: 'info' } }
          ]
        },
        {
          message: 'Log entry two',
          severity: 'info',
          on_complete: [
            { log: { message: 'Entry two hook', severity: 'info' } }
          ]
        }
      ]

      trigger = SaveTriggers::Log.new(config, @activity_log)

      expect(Rails.logger).to receive(:info).with(/Log entry one/)
      expect(Rails.logger).to receive(:info).with(/Entry one hook/)
      expect(Rails.logger).to receive(:info).with(/Log entry two/)
      expect(Rails.logger).to receive(:info).with(/Entry two hook/)
      allow(Rails.logger).to receive(:info)

      trigger.perform_with_lifecycle
    end

    it 'supports both top-level and per-entry hooks simultaneously' do
      # Top-level on_complete fires after the whole perform,
      # per-entry on_complete fires after each entry
      config = {
        message: 'Single entry',
        severity: 'info',
        on_complete: [
          { log: { message: 'Per-entry hook', severity: 'info' } }
        ]
      }

      trigger = SaveTriggers::Log.new(config, @activity_log)

      # For a Hash config, on_complete is extracted by BOTH
      # extract_lifecycle_hooks (top-level) and with_entry_lifecycle (per-entry).
      # Since extract_lifecycle_hooks runs first and deletes it,
      # with_entry_lifecycle won't find it. The top-level hook fires.
      expect(Rails.logger).to receive(:info).with(/Single entry/)
      expect(Rails.logger).to receive(:info).with(/Per-entry hook/)
      allow(Rails.logger).to receive(:info)

      trigger.perform_with_lifecycle
    end

    it 'extracts per-entry on_complete from named config entries without affecting other keys' do
      config = {
        one: {
          with: {
            select_who: 'extraction test'
          },
          on_complete: [
            { log: { message: 'extracted', severity: 'info' } }
          ]
        }
      }

      # After UpdateThis processes the config, on_complete should be
      # extracted from the inner config hash by with_entry_lifecycle.
      # normalize_trigger_config owns a deep copy; with_entry_lifecycle
      # deletes on_complete from the owned copy's entry, not the original.
      allow(Rails.logger).to receive(:info)
      trigger = SaveTriggers::UpdateThis.new(config, @activity_log)
      trigger.perform_with_lifecycle

      # The trigger's owned config entry should have on_complete removed
      expect(trigger.config[:one]).not_to have_key(:on_complete)
      # But other keys should still be present
      expect(trigger.config[:one]).to have_key(:with)
    end
  end
end
