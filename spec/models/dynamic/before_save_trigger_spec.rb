# frozen_string_literal: true

# Tests for save_trigger.before_save - Issue #1382
#
# Prior to this spec, before_save was only covered by a schema-validity check
# (spec/models/option_configs/extra_option_configs/save_trigger_spec.rb) confirming it is
# an accepted config key. These specs demonstrate the actual runtime behavior:
#   - a before_save trigger runs and its effect is persisted as part of the record's own save
#   - a before_save trigger runs before on_create/on_update (after_commit) triggers, so its
#     output is visible to them
#   - an exception raised by a before_save trigger aborts the save entirely, so the record is
#     not persisted at all (in contrast to an on_create/on_update trigger failure, which runs
#     after the record has already been committed)

require 'rails_helper'

RSpec.describe 'save_trigger before_save', type: :model do
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

    al_def = ActivityLog.find(ActivityLog::PlayerContactPhone.definition.id)

    ActivityLog.active.where(item_type: al_def.item_type).where.not(id: al_def.id).each do |oal|
      oal.current_admin = @admin
      oal.disable!
    end

    config = <<~ENDDEF
      before_save_persist_test:
        label: Before Save Persist Test
        fields:
          - select_call_direction
          - select_who

        save_trigger:
          before_save:
            update_this:
              one:
                with:
                  select_who: 'set in before_save'

      before_save_order_test:
        label: Before Save Order Test
        fields:
          - select_call_direction
          - select_who

        save_trigger:
          before_save:
            set_variables:
              name: marker
              value: 'set in before_save'

          on_create:
            update_this:
              one:
                with:
                  select_call_direction: 'on_create saw: {{variables.marker}}'

      before_save_exception_test:
        label: Before Save Exception Test
        fields:
          - select_call_direction
          - select_who

        save_trigger:
          before_save:
            exception:
              message: 'Blocked in before_save'
              if:
                all:
                  this:
                    select_who: 'blocked value'

      before_save_multi_test:
        label: Before Save Multi Test
        fields:
          - select_call_direction
          - select_who

        save_trigger:
          before_save:
            - set_variables:
                name: step_one
                value: 'first'
            - set_variables:
                name: step_two
                value: '{{variables.step_one}}-second'
            - update_this:
                one:
                  with:
                    select_who: '{{variables.step_two}}'

      before_save_conditional_test:
        label: Before Save Conditional Test
        fields:
          - select_call_direction
          - select_who

        save_trigger:
          before_save:
            update_this:
              one:
                if:
                  all:
                    this:
                      select_call_direction: 'trigger me'
                with:
                  select_who: 'set in before_save'

      before_save_reentrant_create_test:
        label: Before Save Reentrant Create Test
        fields:
          - select_call_direction
          - select_who

        save_trigger:
          before_save:
            update_this:
              one:
                with:
                  select_who: 'set in before_save'
          on_create:
            update_this:
              one:
                with:
                  select_call_direction: 'on_create saw: {{select_who}}'

      before_save_reentrant_update_test:
        label: Before Save Reentrant Update Test
        fields:
          - select_call_direction
          - select_who

        save_trigger:
          before_save:
            update_this:
              one:
                with:
                  select_who: 'set in before_save'
          on_update:
            update_this:
              one:
                with:
                  select_call_direction: 'on_update saw: {{select_who}}'

      before_save_reentrant_disable_test:
        label: Before Save Reentrant Disable Test
        fields:
          - select_call_direction
          - select_who

        save_trigger:
          before_save:
            update_this:
              one:
                with:
                  select_who: 'set in before_save'
          on_disable:
            update_this:
              one:
                with:
                  select_call_direction: 'on_disable saw: {{select_who}}'

      before_save_reentrant_embedded_item_test:
        label: Before Save Reentrant Embedded Item Test
        fields:
          - select_call_direction
          - select_who
        references:
          player_contacts:
            from: this
            add: one_to_this

        save_trigger:
          before_save:
            update_this:
              one:
                with:
                  select_who: 'set in before_save'
                  embedded_item:
                    data: '(555)555-5555'

      before_save_downcase_bypass_test:
        label: Before Save Downcase Bypass Test
        fields:
          - select_call_direction
          - select_who

        save_trigger:
          before_save:
            update_this:
              one:
                with:
                  select_who: 'MiXeD CaSe VALUE'

      before_save_valid_if_bypass_test:
        label: Before Save Valid If Bypass Test
        fields:
          - select_call_direction
          - select_who
        valid_if:
          on_save:
            all:
              this:
                select_call_direction: 'allowed value'
                invalid_error_message: 'select_call_direction must be allowed value'

        save_trigger:
          before_save:
            update_this:
              one:
                with:
                  select_call_direction: 'blocked value'
    ENDDEF

    al_def.extra_log_types = config
    al_def.current_admin = @admin
    al_def.force_regenerate = true
    al_def.updated_at = DateTime.now # force a save
    al_def.save!
    ActivityLog.refresh_outdated
    al_def.reload
    al_def.force_option_config_parse

    setup_access :activity_log__player_contact_phones, resource_type: :table, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__before_save_persist_test, resource_type: :activity_log_type,
                                                                                access: :create, user: @user
    setup_access :activity_log__player_contact_phone__before_save_order_test, resource_type: :activity_log_type,
                                                                              access: :create, user: @user
    setup_access :activity_log__player_contact_phone__before_save_exception_test, resource_type: :activity_log_type,
                                                                                  access: :create, user: @user
    setup_access :activity_log__player_contact_phone__before_save_multi_test, resource_type: :activity_log_type,
                                                                              access: :create, user: @user
    setup_access :activity_log__player_contact_phone__before_save_conditional_test, resource_type: :activity_log_type,
                                                                                    access: :create, user: @user
    setup_access :activity_log__player_contact_phone__before_save_reentrant_create_test,
                 resource_type: :activity_log_type, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__before_save_reentrant_update_test,
                 resource_type: :activity_log_type, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__before_save_reentrant_disable_test,
                 resource_type: :activity_log_type, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__before_save_reentrant_embedded_item_test,
                 resource_type: :activity_log_type, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__before_save_downcase_bypass_test,
                 resource_type: :activity_log_type, access: :create, user: @user
    setup_access :activity_log__player_contact_phone__before_save_valid_if_bypass_test,
                 resource_type: :activity_log_type, access: :create, user: @user
    al_def.add_master_association
  end

  describe 'execution timing' do
    it 'persists the effect of a before_save trigger as part of the record\'s own save' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'original value',
                                                                       extra_log_type: 'before_save_persist_test')

      expect(al.select_who).to eq 'set in before_save'

      # Confirm the value was actually written to the database in the same insert,
      # not just held in memory on the returned instance.
      al.reload
      expect(al.select_who).to eq 'set in before_save'
    end

    it 'runs before_save triggers before on_create (after_commit) triggers' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'original value',
                                                                       extra_log_type: 'before_save_order_test')

      # The on_create trigger reads the before_save-set variable via substitution -
      # if it saw a blank value, before_save would not have run first.
      expect(al.select_call_direction).to eq 'on_create saw: set in before_save'
      al.reload
      expect(al.select_call_direction).to eq 'on_create saw: set in before_save'
    end

    it 'runs the before_save trigger again on update, not just on create' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'original value',
                                                                       extra_log_type: 'before_save_persist_test')
      expect(al.select_who).to eq 'set in before_save'

      # update_this (run during the initial before_save) leaves skip_save_trigger
      # set on the item - reset it so the following update actually runs triggers.
      al.skip_save_trigger = false
      al.current_user = @master.current_user
      al.update!(select_who: 'attempted override', select_call_direction: 'updated direction')

      expect(al.select_who).to eq 'set in before_save'
      al.reload
      expect(al.select_who).to eq 'set in before_save'
    end

    it 'runs multiple before_save trigger tasks in sequence' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'original value',
                                                                       extra_log_type: 'before_save_multi_test')

      # step_two's value substitutes step_one's, and the final update_this reads
      # step_two - proving all three tasks ran, in order, within before_save.
      expect(al.select_who).to eq 'first-second'
      al.reload
      expect(al.select_who).to eq 'first-second'
    end
  end

  describe 'exception handling' do
    it 'does not raise or block the save when the before_save condition is not met' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'allowed value',
                                                                       extra_log_type: 'before_save_exception_test')

      expect(al).to be_persisted
    end

    it 'aborts the save and does not persist the record when a before_save trigger raises' do
      count_before = @player_contact.activity_log__player_contact_phones.count

      expect do
        @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                    select_who: 'blocked value',
                                                                    extra_log_type: 'before_save_exception_test')
      end.to raise_error(FphsException, /\ABlocked in before_save/)

      expect(@player_contact.activity_log__player_contact_phones.count).to eq count_before
    end
  end

  describe 'conditional execution' do
    it 'runs the before_save trigger when its if: condition matches' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'trigger me',
                                                                       select_who: 'original value',
                                                                       extra_log_type: 'before_save_conditional_test')

      expect(al.select_who).to eq 'set in before_save'
    end

    it 'does not run the before_save trigger when its if: condition does not match' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'do not trigger',
                                                                       select_who: 'original value',
                                                                       extra_log_type: 'before_save_conditional_test')

      expect(al.select_who).to eq 'original value'
      al.reload
      expect(al.select_who).to eq 'original value'
    end
  end

  # Issue #1384 - a before_save trigger's `update_this` targeting `this` (the record
  # currently being saved) previously performed a reentrant `.update!` call on that
  # not-yet-persisted (or, for update/disable, not-yet-fully-saved) record. That nested
  # save corrupted the outer save's own dirty-tracking (saved_change_to_id?/
  # saved_change_to_updated_at?/saved_change_to_disabled?), so the outer save's
  # on_create/on_update/on_disable trigger dispatch (which relies on those flags via
  # `_created`/`_updated`/`_disabled`) silently picked the wrong action - or none at all.
  describe 'reentrant update_this on this (issue #1384)' do
    it 'fires the on_create trigger for a record whose before_save trigger uses update_this on this' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'original value',
                                                                       extra_log_type: 'before_save_reentrant_create_test')

      expect(al.select_call_direction).to eq 'on_create saw: set in before_save'
      al.reload
      expect(al.select_call_direction).to eq 'on_create saw: set in before_save'
    end

    it 'fires the on_update trigger for a record whose before_save trigger uses update_this on this' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'original value',
                                                                       extra_log_type: 'before_save_reentrant_update_test')
      al.skip_save_trigger = false
      al.current_user = @master.current_user
      al.update!(select_call_direction: 'updated direction')

      expect(al.select_call_direction).to eq 'on_update saw: set in before_save'
      al.reload
      expect(al.select_call_direction).to eq 'on_update saw: set in before_save'
    end

    it 'fires the on_disable trigger for a record whose before_save trigger uses update_this on this' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'original value',
                                                                       extra_log_type: 'before_save_reentrant_disable_test')
      al.skip_save_trigger = false
      al.current_user = @master.current_user
      al.update!(disabled: true)

      expect(al.select_call_direction).to eq 'on_disable saw: set in before_save'
      al.reload
      expect(al.select_call_direction).to eq 'on_disable saw: set in before_save'
    end

    it 'updates an embedded item via update_this called from a before_save trigger' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'original value',
                                                                       extra_log_type: 'before_save_reentrant_embedded_item_test')

      pn = random_phone_number
      ei = al.create_embedded_item({ rank: 10, data: pn, rec_type: :phone })
      expect(ei).to be_a PlayerContact

      # Trigger before_save again (it runs on every save, not just create) - this time
      # an embedded item exists, so update_this's embedded_item: config has something to act on.
      al.skip_save_trigger = false
      al.current_user = @master.current_user
      al.update!(select_call_direction: 'trigger again')

      al.clear_embedded_item_memo
      ei = al.embedded_item
      expect(ei.data).to eq '(555)555-5555'
      ei.reload
      expect(ei.data).to eq '(555)555-5555'
    end
  end

  # Issue #1384 (F2): update_this's before_save branch writes via #assign_attributes
  # (app/models/save_triggers/update_this.rb) rather than a real #update!, so the write
  # happens after the outer save's own validate phase already ran. handle_before_save_triggers
  # (app/models/dynamic/implementation_handler.rb) re-runs #valid? once after all before_save
  # triggers finish, so both normalization (before_validation :downcase_attributes) and
  # validation still apply to values a before_save trigger assigns.
  describe 'validation after before_save triggers (issue #1384)' do
    it 'downcases a value set via a before_save-triggered update_this' do
      al = @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'from player',
                                                                       select_who: 'original value',
                                                                       extra_log_type: 'before_save_downcase_bypass_test')

      expect(al.select_who).to eq 'mixed case value'
      al.reload
      expect(al.select_who).to eq 'mixed case value'
    end

    it 'validates a value set via a before_save-triggered update_this' do
      # valid_if requires select_call_direction: 'allowed value'. The before_save trigger
      # overwrites it with 'blocked value' - the record is re-validated after before_save
      # triggers finish, so the save is rejected instead of silently persisting bad data.
      expect do
        @player_contact.activity_log__player_contact_phones.create!(select_call_direction: 'allowed value',
                                                                    select_who: 'original value',
                                                                    extra_log_type: 'before_save_valid_if_bypass_test')
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'returns false with populated errors from a plain #save, rather than raising' do
      # ActiveRecord::Persistence#save specifically rescues ActiveRecord::RecordInvalid raised
      # anywhere in the callback chain (including from handle_before_save_triggers) and returns
      # false, so plain #save keeps its normal (non-raising) contract even though the record was
      # only made invalid by a before_save trigger, not by the caller's own attributes.
      al = @player_contact.activity_log__player_contact_phones.create(select_call_direction: 'allowed value',
                                                                      select_who: 'original value',
                                                                      extra_log_type: 'before_save_valid_if_bypass_test')

      expect(al).not_to be_persisted
      expect(al.errors.full_messages).not_to be_empty
    end
  end
end
