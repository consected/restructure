# frozen_string_literal: true

require 'rails_helper'

# Tests for per-type validation of trigger task definitions in TriggerTasks.
# Validates that:
# - Trigger action names are checked against ValidSaveTriggers
# - Direct-config triggers validate their keys
# - Named-entry triggers validate keys one level deeper (inside each named entry)
# - Delegate/recursive triggers (transaction, background, case) accept nested definitions
# - Universal keys (if, on_complete, on_failure) are accepted across all types
# - Unrecognized keys produce warnings (not hard errors)
# - Both Hash-style and Array-style task lists are validated
#
# Related GitHub issue: #1058
RSpec.describe 'ExtraOptionConfigs::TriggerTasks per-type validation', type: :model do
  let(:klass) { OptionConfigs::ExtraOptionConfigs::TriggerTasks }

  # ── Trigger action name validation ──────────────────────────────────

  describe 'trigger action name validation' do
    it 'accepts all valid trigger names without warnings' do
      valid_triggers = %i[notify create_reference create_master update_reference
                          create_filestore_container update_this add_tracker
                          change_user_roles pull_external_data set_item_flags
                          redcap_request run_batch_trigger log transaction
                          background reload_this case set_save_trigger_results
                          set_variables generate_document full_text_search]

      # Build a minimal valid config with every trigger name
      config = valid_triggers.each_with_object({}) { |name, h| h[name] = {} }
      instance = klass.new(config)
      expect(instance.config_warnings.select { |w| w[:message]&.match?(/trigger|action|unrecognized/) }).to be_empty
    end

    it 'warns when an unrecognized trigger action name is used in a Hash config' do
      instance = klass.new(bogus_trigger: { some: 'config' })
      warnings = instance.config_warnings.select { |w| w[:message]&.match?(/bogus_trigger/) }
      expect(warnings).not_to be_empty
    end

    it 'warns when an unrecognized trigger action name is used in an Array config' do
      instance = klass.new([{ not_a_real_trigger: { foo: 'bar' } }])
      warnings = instance.config_warnings.select { |w| w[:message]&.match?(/not_a_real_trigger/) }
      expect(warnings).not_to be_empty
    end

    it 'does not produce hard errors for unrecognized trigger names' do
      instance = klass.new(unknown_action: { x: 1 })
      errors = instance.config_errors.select { |e| e[:message]&.match?(/unknown_action/) }
      expect(errors).to be_empty
    end

    it 'warns for multiple unrecognized trigger names in one config' do
      instance = klass.new(fake_one: {}, fake_two: {})
      warnings = instance.config_warnings
      expect(warnings.any? { |w| w[:message]&.match?(/fake_one/) }).to be true
      expect(warnings.any? { |w| w[:message]&.match?(/fake_two/) }).to be true
    end
  end

  # ── Universal keys ──────────────────────────────────────────────────

  describe 'universal keys' do
    it 'accepts :if as a valid key in any trigger type' do
      instance = klass.new(notify: { my_notification: { type: 'email' }, if: { always: true } })
      key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/\bif\b/) }
      expect(key_warnings).to be_empty
    end

    it 'accepts :on_complete as a valid key in any trigger type' do
      instance = klass.new(change_user_roles: { add_role_names: ['role1'], on_complete: { notify: { done: { type: 'email' } } } })
      key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/on_complete/) }
      expect(key_warnings).to be_empty
    end

    it 'accepts :on_failure as a valid key in any trigger type' do
      instance = klass.new(update_this: { fix_it: { with: { status: 'failed' } }, on_failure: { log: { err: { message: 'failed' } } } })
      key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/on_failure/) }
      expect(key_warnings).to be_empty
    end
  end

  # ── Direct-config triggers ──────────────────────────────────────────

  describe 'direct-config trigger key validation' do
    context 'change_user_roles' do
      it 'accepts valid keys without warnings' do
        instance = klass.new(change_user_roles: { add_role_names: ['admin'], remove_role_names: ['guest'], if: { always: true } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/change_user_roles/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys' do
        instance = klass.new(change_user_roles: { add_role_names: ['admin'], bogus_key: 'val' })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/bogus_key/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'set_item_flags' do
      it 'accepts valid keys without warnings' do
        instance = klass.new(set_item_flags: { flags: { completed: true }, first: true })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/set_item_flags/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys' do
        instance = klass.new(set_item_flags: { flags: { done: true }, invalid_option: 'x' })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/invalid_option/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'create_filestore_container' do
      it 'accepts valid keys without warnings' do
        instance = klass.new(create_filestore_container: { name: 'docs', label: 'Documents', create_with_role: 'file_admin' })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/create_filestore_container/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys' do
        instance = klass.new(create_filestore_container: { name: 'docs', unknown_opt: true })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/unknown_opt/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'reload_this' do
      it 'accepts valid keys (if, on_complete, on_failure) without warnings' do
        instance = klass.new(reload_this: { if: { always: true }, on_complete: {} })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/reload_this/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys' do
        instance = klass.new(reload_this: { spurious: 'value' })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/spurious/) }
        expect(key_warnings).not_to be_empty
      end
    end
  end

  # ── Named-entry triggers ────────────────────────────────────────────

  describe 'named-entry trigger key validation' do
    context 'notify' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(notify: { my_email: { type: 'email', role: 'admin', subject: 'Test' } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/notify/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(notify: { my_email: { type: 'email', not_a_notify_key: 'val' } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/not_a_notify_key/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'create_reference' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(create_reference: { new_ref: { in: 'some_model', with: { field: 'val' }, force_create: true } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/create_reference/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(create_reference: { new_ref: { in: 'some_model', invalid_inner_key: true } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/invalid_inner_key/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'update_this' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(update_this: { do_update: { with: { status: 'done' }, force_not_editable_save: true } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/update_this/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(update_this: { do_update: { with: { status: 'done' }, mystery_key: 'x' } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/mystery_key/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'update_reference' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(update_reference: { upd_ref: { with: { field: 'val' }, first: true } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/update_reference/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(update_reference: { upd_ref: { with: { field: 'val' }, wrong_key: 1 } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/wrong_key/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'add_tracker' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(add_tracker: { track_it: { with: { protocol: 'A', sub_process: 'B' } } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/add_tracker/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(add_tracker: { track_it: { with: {}, bad_opt: true } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/bad_opt/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'pull_external_data' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(pull_external_data: { api_call: { method: 'get', from: 'http://example.com', data_field: 'result' } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/pull_external_data/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(pull_external_data: { api_call: { method: 'get', from: 'http://example.com', nonsense: true } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/nonsense/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'run_batch_trigger' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(run_batch_trigger: { batch1: { resource_name: 'my_resource', mode: 'create', limit: 10 } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/run_batch_trigger/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(run_batch_trigger: { batch1: { resource_name: 'x', extra_junk: 'y' } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/extra_junk/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'set_save_trigger_results' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(set_save_trigger_results: { res1: { element: 'count', value: 42 } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/set_save_trigger_results/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(set_save_trigger_results: { res1: { element: 'count', unrecognized: true } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/unrecognized/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'set_variables' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(set_variables: { var1: { name: 'x', value: 'y' } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/set_variables/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(set_variables: { var1: { name: 'x', value: 'y', bad_key: true } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/bad_key/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'log' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(log: { log1: { message: 'hello', severity: 'info' } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/\blog\b/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(log: { log1: { message: 'hello', wrong_field: true } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/wrong_field/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'generate_document' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(generate_document: { doc1: { content_template_name: 'template', filename: 'out.pdf' } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/generate_document/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(generate_document: { doc1: { content_template_name: 'template', weird_option: 'x' } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/weird_option/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'redcap_request' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(redcap_request: { rc1: { study: 'study1', project_name: 'proj', method: 'post' } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/redcap_request/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(redcap_request: { rc1: { study: 'study1', wrong_opt: true } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/wrong_opt/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'create_master' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(create_master: { new_master: { force_create: true, with: { field: 'val' } } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/create_master/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(create_master: { new_master: { force_create: true, invalid_key: 'x' } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/invalid_key/) }
        expect(key_warnings).not_to be_empty
      end
    end

    context 'full_text_search' do
      it 'accepts valid keys inside the named entry without warnings' do
        instance = klass.new(full_text_search: { fts1: { source_fields: ['name'], target_column: 'search_col' } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/full_text_search/) }
        expect(key_warnings).to be_empty
      end

      it 'accepts separate-table mode keys without warnings' do
        instance = klass.new(full_text_search: { fts1: {
                               source_fields: ['name'],
                               target_column: 'search_vector',
                               target_table: 'schema_name.records_search_index',
                               target_foreign_key_column: 'source_record_id'
                             } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/full_text_search|target_table|target_foreign_key_column/) }
        expect(key_warnings).to be_empty
      end

      it 'warns on unrecognized keys inside the named entry' do
        instance = klass.new(full_text_search: { fts1: { source_fields: ['name'], fake_setting: 'y' } })
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/fake_setting/) }
        expect(key_warnings).not_to be_empty
      end
    end

    it 'validates keys inside each named entry, not the arbitrary entry names themselves' do
      # The outer key "my_custom_label" is the arbitrary entry name — should not warn
      # The inner key "bad_inner_key" is not a valid notify key — should warn
      instance = klass.new(notify: { my_custom_label: { type: 'email', bad_inner_key: 'x' } })
      label_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/my_custom_label/) }
      inner_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/bad_inner_key/) }
      expect(label_warnings).to be_empty
      expect(inner_warnings).not_to be_empty
    end
  end

  # ── Delegate/recursive triggers ─────────────────────────────────────

  describe 'delegate/recursive trigger validation' do
    context 'transaction' do
      it 'accepts nested trigger definitions without key validation on content' do
        instance = klass.new(transaction: [{ notify: { n1: { type: 'email' } } }, { update_this: { u1: { with: {} } } }])
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/transaction/) }
        expect(key_warnings).to be_empty
      end

      it 'does not warn on the trigger name itself' do
        instance = klass.new(transaction: [])
        name_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/transaction/) }
        expect(name_warnings).to be_empty
      end
    end

    context 'background' do
      it 'accepts nested trigger definitions without key validation on content' do
        instance = klass.new(background: [{ log: { l1: { message: 'bg task' } } }])
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/background/) }
        expect(key_warnings).to be_empty
      end
    end

    context 'case' do
      it 'accepts case structure without key validation on content' do
        instance = klass.new(case: [{ when: { condition: true }, then: { notify: { n: { type: 'email' } } } }])
        key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/\bcase\b/) }
        expect(key_warnings).to be_empty
      end
    end
  end

  # ── Nested validation propagation for delegate triggers ─────────────

  describe 'nested validation propagation for delegate triggers' do
    context 'transaction' do
      it 'warns when a nested trigger uses an unrecognized action name' do
        instance = klass.new(transaction: [{ notifyy: { n1: { type: 'email' } } }])
        warnings = instance.config_warnings.select { |w| w[:message]&.match?(/notifyy/) }
        expect(warnings).not_to be_empty
      end

      it 'warns when a nested trigger has an unrecognized key inside a named entry' do
        instance = klass.new(transaction: [{ notify: { n1: { type: 'email', not_a_notify_key: 1 } } }])
        warnings = instance.config_warnings.select { |w| w[:message]&.match?(/not_a_notify_key/) }
        expect(warnings).not_to be_empty
      end

      it 'warns on unrecognized keys for a direct-config trigger nested inside transaction' do
        instance = klass.new(transaction: [{ change_user_roles: { add_role_names: ['admin'], bogus_inner: 'x' } }])
        warnings = instance.config_warnings.select { |w| w[:message]&.match?(/bogus_inner/) }
        expect(warnings).not_to be_empty
      end

      it 'recurses into transaction nested inside transaction' do
        instance = klass.new(transaction: [{ transaction: [{ notify: { n1: { type: 'email', bad_one: 1 } } }] }])
        warnings = instance.config_warnings.select { |w| w[:message]&.match?(/bad_one/) }
        expect(warnings).not_to be_empty
      end
    end

    context 'background' do
      it 'warns when a nested trigger uses an unrecognized action name' do
        instance = klass.new(background: [{ fake_action: { x: 1 } }])
        warnings = instance.config_warnings.select { |w| w[:message]&.match?(/fake_action/) }
        expect(warnings).not_to be_empty
      end

      it 'warns when a nested trigger has unrecognized keys' do
        instance = klass.new(background: [{ log: { l1: { message: 'ok', wrong_field: true } } }])
        warnings = instance.config_warnings.select { |w| w[:message]&.match?(/wrong_field/) }
        expect(warnings).not_to be_empty
      end
    end

    context 'case' do
      it 'warns on unrecognized action names inside a then branch' do
        instance = klass.new(case: [{ when: { all: { this: { f: 1 } } }, then: [{ bogus_trigger: {} }] }])
        warnings = instance.config_warnings.select { |w| w[:message]&.match?(/bogus_trigger/) }
        expect(warnings).not_to be_empty
      end

      it 'warns on unrecognized keys inside triggers in a then branch' do
        instance = klass.new(case: [{ when: { all: { this: { f: 1 } } },
                                      then: [{ notify: { n1: { type: 'email', invalid_inner: 'y' } } }] }])
        warnings = instance.config_warnings.select { |w| w[:message]&.match?(/invalid_inner/) }
        expect(warnings).not_to be_empty
      end

      it 'warns on unrecognized action names inside an else branch' do
        instance = klass.new(case: [{ else: [{ phantom: {} }] }])
        warnings = instance.config_warnings.select { |w| w[:message]&.match?(/phantom/) }
        expect(warnings).not_to be_empty
      end

      it 'does not warn for valid then/else branches' do
        instance = klass.new(case: [
                               { when: { all: { this: { f: 1 } } }, then: [{ notify: { n1: { type: 'email' } } }] },
                               { else: [{ log: { l1: { message: 'no match' } } }] }
                             ])
        expect(instance.config_warnings).to be_empty
      end
    end
  end

  # ── Array-style task lists ──────────────────────────────────────────

  describe 'array-style task list validation' do
    it 'validates trigger names in each array entry' do
      instance = klass.new([
                             { notify: { n1: { type: 'email' } } },
                             { fake_trigger: { some: 'config' } }
                           ])
      warnings = instance.config_warnings.select { |w| w[:message]&.match?(/fake_trigger/) }
      expect(warnings).not_to be_empty
    end

    it 'validates keys inside named-entry triggers within array entries' do
      instance = klass.new([
                             { notify: { n1: { type: 'email', bogus: true } } }
                           ])
      warnings = instance.config_warnings.select { |w| w[:message]&.match?(/bogus/) }
      expect(warnings).not_to be_empty
    end

    it 'validates keys for direct-config triggers within array entries' do
      instance = klass.new([
                             { change_user_roles: { add_role_names: ['admin'], phantom_key: 'val' } }
                           ])
      warnings = instance.config_warnings.select { |w| w[:message]&.match?(/phantom_key/) }
      expect(warnings).not_to be_empty
    end

    it 'does not warn for valid array entries' do
      instance = klass.new([
                             { notify: { n1: { type: 'email' } } },
                             { change_user_roles: { add_role_names: ['admin'] } },
                             { transaction: [{ log: { l1: { message: 'done' } } }] }
                           ])
      expect(instance.config_warnings).to be_empty
    end
  end

  # ── Mixed valid and invalid configs ─────────────────────────────────

  describe 'mixed valid and invalid configurations' do
    it 'reports warnings only for invalid parts while accepting valid parts' do
      instance = klass.new(
        notify: { n1: { type: 'email' } }, # valid
        change_user_roles: { add_role_names: ['admin'] }, # valid
        fake_action: { x: 1 },                                    # invalid trigger name
        update_this: { u1: { with: { field: 'v' }, bad_key: 1 } } # valid trigger, invalid inner key
      )
      # Should warn about fake_action
      expect(instance.config_warnings.any? { |w| w[:message]&.match?(/fake_action/) }).to be true
      # Should warn about bad_key
      expect(instance.config_warnings.any? { |w| w[:message]&.match?(/bad_key/) }).to be true
      # Should not have hard errors for these
      expect(instance.config_errors.select { |e| e[:message]&.match?(/fake_action|bad_key/) }).to be_empty
    end
  end

  # ── Warning severity ────────────────────────────────────────────────

  describe 'warning severity' do
    it 'reports unrecognized trigger names as warnings not errors' do
      instance = klass.new(nonsense_trigger: { a: 1 })
      expect(instance.config_warnings).not_to be_empty
      trigger_errors = instance.config_errors.select { |e| e[:message]&.match?(/nonsense_trigger/) }
      expect(trigger_errors).to be_empty
    end

    it 'reports unrecognized keys within triggers as warnings not errors' do
      instance = klass.new(notify: { n1: { type: 'email', garbage_key: 'x' } })
      expect(instance.config_warnings).not_to be_empty
      key_errors = instance.config_errors.select { |e| e[:message]&.match?(/garbage_key/) }
      expect(key_errors).to be_empty
    end
  end
end
