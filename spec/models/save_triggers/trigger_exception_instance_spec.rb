# frozen_string_literal: true

# Tests for Issue #1121: Trigger exception needs to include details of triggering instance
#
# When a save trigger or batch trigger raises a FphsException, the re-raised exception
# message should include the class name and ID of the instance that fired the trigger.
# This makes it possible to diagnose which specific record caused the problem.
#
# Implementation locations:
# - OptionConfigs::ExtraOptionImplementers::SaveTriggers#calc_triggers (save_triggers.rb)
# - SaveTriggers::SaveTriggersBase#execute_trigger_list (save_triggers_base.rb)
# - SaveTriggers::SaveTriggersBase#execute_lifecycle_triggers (save_triggers_base.rb)

require 'rails_helper'

RSpec.describe 'Trigger exception includes triggering instance details - Issue #1121', type: :model do
  include ModelSupport
  include PlayerContactSupport

  # Helper: set up the ActivityLog definition with given extra_log_types YAML config,
  # refresh all related dynamic definitions, and grant the user access to each named type.
  def configure_al_def(al_def, config_yaml, type_names)
    al_def.extra_log_types = config_yaml
    al_def.current_admin = @admin
    al_def.force_regenerate = true
    al_def.updated_at = DateTime.now
    al_def.save!
    ActivityLog.refresh_outdated
    al_def.reload
    al_def.force_option_config_parse

    unless al_def.option_configs_names.include?(type_names.first)
      Application.refresh_dynamic_defs
    end

    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__blank_log, resource_type: :activity_log_type, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__primary, resource_type: :activity_log_type, access: :create, user: @user

    type_names.each do |type_name|
      setup_access :"activity_log__player_contact_phone__#{type_name}", resource_type: :activity_log_type,
                                                                        access: :create, user: @user
    end

    al_def.add_master_association
    al_def
  end

  # Standard before-each shared setup: user, master, player contact
  def common_setup
    create_user
    setup_access :player_contacts
    let_user_create_player_contacts
    create_item(data: rand(10_000_000_000_000_000), rank: 10)
    @player_contact.master.current_user = @user
    @master = @player_contact.master
    expect(@master).not_to be nil

    al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)
    ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
      oal.current_admin = @admin
      oal.disable!
    end
    al_def
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Save trigger tests
  # ─────────────────────────────────────────────────────────────────────────────

  describe 'save trigger exception includes triggering instance details' do
    before :each do
      al_def = common_setup

      # Configure a save trigger whose on_create attempts to create a player_contact
      # the user does NOT have permission to create (no :create access to player_contacts
      # resource is revoked after setup so the trigger will be denied).
      config = <<~ENDDEF
        trigger_exception_test:
          label: Trigger Exception Test
          fields:
            - select_call_direction
            - select_who

          save_trigger:
            on_create:
              create_reference:
                player_contact:
                  in: master
                  with:
                    rank: 10
                    rec_type: email
                    data: fail@test.tst

      ENDDEF

      configure_al_def(al_def, config, %i[trigger_exception_test])
      @al_def = al_def

      # Revoke create access to player_contacts so the trigger will fail with an FphsException.
      # Use :update (not :read) so sync_set_related_fields can still update the existing player_contact
      # rank via set_related_player_contact_rank - otherwise that after_save callback raises before
      # the save trigger's after_commit has a chance to run.
      setup_access :player_contacts, access: :update, user: @user
    end

    it 'includes the triggering instance class name in the save trigger exception message - Issue #1121' do
      expect do
        @player_contact.activity_log__player_contact_phones.create!(
          select_call_direction: 'from player',
          select_who: 'user',
          extra_log_type: 'trigger_exception_test'
        )
      end.to raise_error(FphsException, /ActivityLog::PlayerContactPhone/)
    end

    it 'includes the triggering instance ID in the save trigger exception message - Issue #1121' do
      # Create the record first so it has an id, then update to trigger on_update
      # Instead, use on_create: create the record and capture the exception from the on_create trigger

      # We need the record to exist first to capture its ID, so we temporarily
      # bypass the trigger, create the record, then re-enable the trigger
      # and update to fire on_update.  But since the config only has on_create,
      # we check on_create path: the instance must have been persisted (has an id)
      # by the time the trigger fires – but actually new records are saved first,
      # then after_create fires the trigger. So we expect the id to be present.
      caught_error = nil
      begin
        @player_contact.activity_log__player_contact_phones.create!(
          select_call_direction: 'from player',
          select_who: 'user',
          extra_log_type: 'trigger_exception_test'
        )
      rescue FphsException => e
        caught_error = e
      end

      expect(caught_error).not_to be_nil
      # The ID should be a number and present in the message
      expect(caught_error.message).to match(/#\d+/)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # Batch trigger tests
  # ─────────────────────────────────────────────────────────────────────────────

  describe 'batch trigger exception includes triggering instance details' do
    before :each do
      al_def = common_setup

      # Configure a batch trigger whose on_record attempts to create a player_contact
      # without the user having create permission, so it will fail.
      config = <<~ENDDEF
        batch_exception_test:
          label: Batch Exception Test
          fields:
            - select_call_direction
            - select_who

          batch_trigger:
            on_record:
              create_reference:
                player_contact:
                  in: master
                  with:
                    rank: 10
                    rec_type: email
                    data: batchfail@test.tst

      ENDDEF

      configure_al_def(al_def, config, %i[batch_exception_test])
      @al_def = al_def

      # Create a record that the batch trigger will process
      @al_record = @player_contact.activity_log__player_contact_phones.create!(
        select_call_direction: 'from player',
        select_who: 'user',
        extra_log_type: 'batch_exception_test'
      )

      # Revoke create access to player_contacts so the batch trigger will fail
      setup_access :player_contacts, access: :read, user: @user
    end

    it 'includes the triggering instance class name in the batch trigger exception message - Issue #1121' do
      @al_record.reload
      @al_record.skip_save_trigger = false
      @al_record.current_user = @user

      expect do
        @al_record.handle_record_batch_trigger
      end.to raise_error(FphsException, /ActivityLog::PlayerContactPhone/)
    end

    it 'includes the triggering instance ID in the batch trigger exception message - Issue #1121' do
      record_id = @al_record.id
      @al_record.reload
      @al_record.skip_save_trigger = false
      @al_record.current_user = @user

      expect do
        @al_record.handle_record_batch_trigger
      end.to raise_error(FphsException, /##{record_id}/)
    end

    it 'includes triggering instance details when trigger_batch_now raises - Issue #1121' do
      @al_record.reload
      @al_record.skip_save_trigger = false
      @al_record.current_user = @master.current_user

      record_id = @al_record.id

      expect do
        @al_record.class.trigger_batch_now
      end.to raise_error(FphsException, /ActivityLog::PlayerContactPhone/)
    end
  end

  # ─────────────────────────────────────────────────────────────────────────────
  # execute_trigger_list and calc_triggers unit tests
  # ─────────────────────────────────────────────────────────────────────────────

  describe 'execute_trigger_list exception includes triggering instance details' do
    before :each do
      al_def = common_setup

      al_def.extra_log_types = <<~END_DEF
        step_1:
          label: Step 1
          fields:
            - select_call_direction
            - select_who
      END_DEF

      configure_al_def(al_def, al_def.extra_log_types, %i[step_1])

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

    it 'includes class name and ID of the item in execute_trigger_list exception - Issue #1121' do
      # Construct a trigger list that will fail (unknown trigger name triggers FphsException)
      trigger_list = [
        { invalid_trigger_for_instance_test: { message: 'should fail' } }
      ]

      base_trigger = SaveTriggers::Log.new({ message: 'test' }, @activity_log)
      instance_class = @activity_log.class.name
      instance_id = @activity_log.id

      expect { base_trigger.send(:execute_trigger_list, trigger_list) }.to raise_error(FphsException) do |error|
        expect(error.message).to include(instance_class)
        expect(error.message).to include("##{instance_id}")
      end
    end

    it 'includes class name and ID of the item in calc_triggers exception - Issue #1121' do
      configs = { nonexistent_trigger_instance_test: { key: 'instance_value' } }
      instance_class = @activity_log.class.name
      instance_id = @activity_log.id

      error = nil
      begin
        OptionConfigs::ExtraOptionImplementers::SaveTriggers::ClassMethods
          .instance_method(:calc_triggers)
          .bind_call(OptionConfigs::ExtraOptions, @activity_log, configs)
      rescue FphsException => e
        error = e
      end

      expect(error).to be_a(FphsException)
      expect(error.message).to include(instance_class)
      expect(error.message).to include("##{instance_id}")
    end
  end
end
