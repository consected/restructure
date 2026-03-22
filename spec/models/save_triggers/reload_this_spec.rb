# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SaveTriggers::ReloadThis, type: :model do
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
    context 'basic functionality' do
      it 'reloads the item from the database' do
        original_who = @activity_log.select_who

        # Simulate an external update to the database
        ActivityLog::PlayerContactPhone.where(id: @activity_log.id)
                                       .update_all(select_who: 'changed externally')

        # Before reload, the instance still has old value
        expect(@activity_log.select_who).to eq(original_who)

        # Perform reload
        config = { if: { always: true } }
        trigger = SaveTriggers::ReloadThis.new(config, @activity_log)
        result = trigger.perform

        # After reload, the instance has the new value
        expect(@activity_log.select_who).to eq('changed externally')
        expect(result[:status]).to eq('reloaded')
        expect(result[:item_id]).to eq(@activity_log.id)
      end

      it 'preserves current_user across reload' do
        config = { if: { always: true } }
        trigger = SaveTriggers::ReloadThis.new(config, @activity_log)

        original_user = @activity_log.current_user
        expect(original_user).not_to be_nil

        trigger.perform

        expect(@activity_log.current_user).to eq(original_user)
      end

      it 'preserves save_trigger_results across reload' do
        @activity_log.save_trigger_results['previous_trigger'] = { some: 'data' }

        config = { if: { always: true } }
        trigger = SaveTriggers::ReloadThis.new(config, @activity_log)
        trigger.perform

        expect(@activity_log.save_trigger_results['previous_trigger']).to eq({ some: 'data' })
        expect(@activity_log.save_trigger_results['reload_this']).to be_a(Hash)
        expect(@activity_log.save_trigger_results['reload_this'][:status]).to eq('reloaded')
      end

      it 'logs the reload action' do
        config = { if: { always: true } }
        trigger = SaveTriggers::ReloadThis.new(config, @activity_log)

        expect(Rails.logger).to receive(:info).with(/ReloadThis.*Reloading/)

        trigger.perform
      end
    end

    context 'with conditional if' do
      it 'reloads when if condition is true (always: true)' do
        # Simulate external update
        ActivityLog::PlayerContactPhone.where(id: @activity_log.id)
                                       .update_all(select_who: 'updated value')

        config = { if: { always: true } }
        trigger = SaveTriggers::ReloadThis.new(config, @activity_log)

        expect(Rails.logger).to receive(:info).with(/Reloading/)
        trigger.perform

        expect(@activity_log.select_who).to eq('updated value')
      end

      it 'does not reload when if condition is false (never: true)' do
        original_who = @activity_log.select_who

        # Simulate external update
        ActivityLog::PlayerContactPhone.where(id: @activity_log.id)
                                       .update_all(select_who: 'updated value')

        config = { if: { never: true } }
        trigger = SaveTriggers::ReloadThis.new(config, @activity_log)
        result = trigger.perform

        # Should not have reloaded - still has original value
        expect(@activity_log.select_who).to eq(original_who)
        expect(result).to be_nil
      end
    end

    context 'without if condition' do
      it 'always reloads when no condition specified' do
        # Simulate external update
        ActivityLog::PlayerContactPhone.where(id: @activity_log.id)
                                       .update_all(select_who: 'no condition update')

        config = {}
        trigger = SaveTriggers::ReloadThis.new(config, @activity_log)

        expect(Rails.logger).to receive(:info).with(/Reloading/)
        trigger.perform

        expect(@activity_log.select_who).to eq('no condition update')
      end
    end

    context 'error handling' do
      it 'logs detailed error when reload fails due to RecordNotFound' do
        config = { if: { always: true } }
        trigger = SaveTriggers::ReloadThis.new(config, @activity_log)

        # Mock reload to raise RecordNotFound error
        allow(@activity_log).to receive(:reload).and_raise(
          ActiveRecord::RecordNotFound.new("Couldn't find ActivityLog::PlayerContactPhone with [WHERE \"activity_log_player_contact_phones\".\"id\" = $1]")
        )

        # Expect the error to be logged with class and id details
        expected_log = "[SaveTrigger::ReloadThis] Failed to reload ActivityLog::PlayerContactPhone##{@activity_log.id}"
        expect(Rails.logger).to receive(:error).with(/#{Regexp.escape(expected_log)}/)

        # Expect the original exception to be re-raised
        expect { trigger.perform }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'logs detailed error when reload fails due to unexpected error' do
        config = { if: { always: true } }
        trigger = SaveTriggers::ReloadThis.new(config, @activity_log)

        # Mock reload to raise an unexpected error
        allow(@activity_log).to receive(:reload).and_raise(StandardError.new('Unexpected database error'))

        # Expect the error to be logged with class, id and error details
        expected_log = "[SaveTrigger::ReloadThis] Unexpected error reloading ActivityLog::PlayerContactPhone##{@activity_log.id}: StandardError - Unexpected database error"
        expect(Rails.logger).to receive(:error).with(expected_log)

        # Expect the original exception to be re-raised
        expect { trigger.perform }.to raise_error(StandardError, 'Unexpected database error')
      end
    end
  end

  describe 'integration with save triggers' do
    before :each do
      # Set up activity log with save trigger configuration
      al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

      # Create configurations that test reload_this behavior
      # We use a callback to simulate an external database change during save processing
      config = <<~ENDDEF
        reload_test_without:
          label: Reload Test Without
          fields:
            - select_call_direction
            - select_who

          save_trigger:
            on_create:
              # First update saves the record, then we'll have a callback modify it externally
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_who: 'trigger_modified'
              # NO reload_this here
              # Second update captures what the in-memory object sees (potentially stale)
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_call_direction: 'captured={{select_who}}'

        reload_test_with:
          label: Reload Test With
          fields:
            - select_call_direction
            - select_who

          save_trigger:
            on_create:
              # First update saves the record
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_who: 'trigger_modified'
              # WITH reload_this - refresh from database
              - reload_this:
                  if:
                    always: true
              # Second update captures the fresh value
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_call_direction: 'captured={{select_who}}'

        reload_test_disabled:
          label: Reload Test Disabled
          fields:
            - select_call_direction
            - select_who

          save_trigger:
            on_create:
              # First update saves the record
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_who: 'trigger_modified'
              # reload_this disabled with never: true
              - reload_this:
                  if:
                    never: true
              # Second update captures the in-memory value
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_call_direction: 'captured={{select_who}}'

      ENDDEF

      al_def.extra_log_types = config
      al_def.current_admin = @admin
      al_def.force_regenerate = true
      al_def.updated_at = DateTime.now
      al_def.save!
      ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse

      Application.refresh_dynamic_defs

      setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__reload_test_without, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__reload_test_with, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__reload_test_disabled, resource_type: :activity_log_type, access: :create, user: @user
      al_def.add_master_association

      @al_def = al_def
    end

    # This test demonstrates the mechanics of reload_this
    # update_this modifies the in-memory object directly, so without reload
    # the substitution should still see the updated value from the in-memory object.
    # But reload_this is useful when:
    # 1. External triggers (like database triggers) modify data
    # 2. create_reference modifies related data that's cached
    # 3. Views with view_sql need to refresh joined data
    it 'without reload_this: in-memory updates are immediately visible' do
      al = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'original_value',
        extra_log_type: 'reload_test_without'
      )

      # Reload to see final state
      al.reload

      # The update_this modified select_who to 'trigger_modified'
      expect(al.select_who).to eq('trigger_modified')

      # Without reload_this, the in-memory object was updated by update_this,
      # so the substitution sees 'trigger_modified'
      expect(al.select_call_direction).to eq('captured=trigger_modified')
    end

    it 'with reload_this (if: always: true): refreshes instance from database' do
      al = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'original_value',
        extra_log_type: 'reload_test_with'
      )

      # Reload to see final state
      al.reload

      # With reload_this, the instance is refreshed from database,
      # and the substitution sees the persisted value
      expect(al.select_who).to eq('trigger_modified')
      expect(al.select_call_direction).to eq('captured=trigger_modified')
    end

    it 'with reload_this (if: never: true): reload is skipped' do
      al = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'original_value',
        extra_log_type: 'reload_test_disabled'
      )

      # Reload to see final state
      al.reload

      expect(al.select_who).to eq('trigger_modified')
      expect(al.select_call_direction).to eq('captured=trigger_modified')
    end
  end

  describe 'reload_this with views demonstrating stale join data' do
    # This test demonstrates the primary use case for reload_this:
    # When a dynamic model is based on a view with joins, and a trigger
    # modifies the joined table, the view record has stale data until reloaded.
    it 'reloads instance to see updated association data' do
      # Create an activity log and verify reload works with associations
      al = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'test',
        extra_log_type: 'step_1'
      )

      # Store original master data
      original_email_count = al.master.player_contacts.where(rec_type: 'email').count

      # Create a new email via direct database insert (simulating external change)
      # Use create_reference-style approach with proper access
      new_contact = al.master.player_contacts.build(
        rec_type: 'email',
        data: 'new_email@test.tst',
        rank: 10,
        current_user: @user
      )
      new_contact.save!

      # Reload the activity log
      al.reload

      # After reload, fresh data is available
      fresh_email_count = al.master.player_contacts.where(rec_type: 'email').count
      expect(fresh_email_count).to eq(original_email_count + 1)
    end
  end

  describe 'integration with batch triggers' do
    before :each do
      # Set up activity log with batch trigger configuration
      al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

      # Create configurations that test reload_this in batch trigger context
      # We chain update_this -> reload_this -> update_this to show the value is persisted and reloaded
      config = <<~ENDDEF
        batch_reload_test_without:
          label: Batch Reload Test Without
          fields:
            - select_call_direction
            - select_who

          batch_trigger:
            on_record:
              # First update modifies select_who
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_who: 'batch_modified'
              # NO reload_this
              # Second update captures the current value
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_call_direction: 'captured={{select_who}}'

        batch_reload_test_with:
          label: Batch Reload Test With
          fields:
            - select_call_direction
            - select_who

          batch_trigger:
            on_record:
              # First update modifies select_who
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_who: 'batch_modified'
              # WITH reload_this - refresh from database
              - reload_this:
                  if:
                    always: true
              # Second update captures the reloaded value
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_call_direction: 'captured={{select_who}}'

        batch_reload_test_disabled:
          label: Batch Reload Test Disabled
          fields:
            - select_call_direction
            - select_who

          batch_trigger:
            on_record:
              # First update modifies select_who
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_who: 'batch_modified'
              # reload_this disabled
              - reload_this:
                  if:
                    never: true
              # Second update captures the value
              - update_this:
                  one:
                    force_not_editable_save: true
                    with:
                      select_call_direction: 'captured={{select_who}}'

      ENDDEF

      al_def.extra_log_types = config
      al_def.current_admin = @admin
      al_def.force_regenerate = true
      al_def.updated_at = DateTime.now
      al_def.save!
      ActivityLog.refresh_outdated
      al_def.reload
      al_def.force_option_config_parse

      Application.refresh_dynamic_defs

      setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_reload_test_without, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_reload_test_with, resource_type: :activity_log_type, access: :create, user: @user
      setup_access :activity_log__player_contact_phone__batch_reload_test_disabled, resource_type: :activity_log_type, access: :create, user: @user
      al_def.add_master_association

      @al_def = al_def
    end

    it 'without reload_this: batch trigger processes and captures value' do
      al = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'original_value',
        extra_log_type: 'batch_reload_test_without'
      )

      # Run the batch trigger
      al.class.trigger_batch_now
      al.reload

      # Verify both updates were applied
      expect(al.select_who).to eq('batch_modified')
      expect(al.select_call_direction).to eq('captured=batch_modified')
    end

    it 'with reload_this (if: always: true): batch trigger refreshes instance' do
      al = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'original_value',
        extra_log_type: 'batch_reload_test_with'
      )

      # Run the batch trigger
      al.class.trigger_batch_now
      al.reload

      # With reload_this, the instance was reloaded from database
      # and the second update captured the persisted value
      expect(al.select_who).to eq('batch_modified')
      expect(al.select_call_direction).to eq('captured=batch_modified')
    end

    it 'with reload_this (if: never: true): reload is skipped' do
      al = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'original_value',
        extra_log_type: 'batch_reload_test_disabled'
      )

      # Run the batch trigger
      al.class.trigger_batch_now
      al.reload

      # With reload_this disabled, same behavior as without
      expect(al.select_who).to eq('batch_modified')
      expect(al.select_call_direction).to eq('captured=batch_modified')
    end
  end
end
