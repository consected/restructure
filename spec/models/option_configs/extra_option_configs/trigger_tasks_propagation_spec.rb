# frozen_string_literal: true

require 'rails_helper'

# Integration tests verifying that per-type trigger validation warnings
# produced inside TriggerTasks instances propagate up to the parent
# BaseConfiguration classes that contain them:
#
#   - SaveTrigger  (on_create / on_update / on_save / on_upload / on_disable / before_save)
#   - BatchTrigger (on_record)
#   - ConfigTrigger (on_define)
#
# Covers the recursive validation behavior introduced for issue #1058 so
# that typos in trigger names or invalid keys appearing inside a nested
# transaction/background/case block surface on the owning configuration
# object via config_warnings.
RSpec.describe 'TriggerTasks per-type validation propagation', type: :model do
  # ── SaveTrigger ─────────────────────────────────────────────────────

  describe OptionConfigs::ExtraOptionConfigs::SaveTrigger do
    let(:klass) { described_class }

    it 'surfaces a nested unrecognized trigger name warning from on_create' do
      instance = klass.new(on_create: [{ bogus_trigger: { x: 1 } }])
      messages = instance.config_warnings.map { |w| w[:message].to_s }
      expect(messages.any? { |m| m.include?('bogus_trigger') }).to be true
    end

    it 'surfaces a nested key warning from on_update' do
      instance = klass.new(on_update: [{ notify: { type: 'email', spurious_inner: 'x' } }])
      messages = instance.config_warnings.map { |w| w[:message].to_s }
      expect(messages.any? { |m| m.include?('spurious_inner') }).to be true
    end

    it 'surfaces a warning for an invalid trigger nested inside a transaction delegate' do
      instance = klass.new(on_create: [{ transaction: [{ notifyy: { n1: { type: 'email' } } }] }])
      messages = instance.config_warnings.map { |w| w[:message].to_s }
      expect(messages.any? { |m| m.include?('notifyy') }).to be true
    end

    it 'surfaces a warning for an invalid key nested inside a case then-branch' do
      instance = klass.new(on_create: [{ case: [{ when: { all: { this: { f: 1 } } },
                                                  then: [{ notify: { type: 'email', wrong_inner: 'y' } }] }] }])
      messages = instance.config_warnings.map { |w| w[:message].to_s }
      expect(messages.any? { |m| m.include?('wrong_inner') }).to be true
    end

    it 'tags propagated warnings with the parent trigger attribute name' do
      instance = klass.new(on_update: [{ phantom_action: {} }])
      tagged = instance.config_warnings.select { |w| w[:parent_attribute] == :on_update }
      expect(tagged).not_to be_empty
    end

    it 'does not surface warnings when nested triggers are valid' do
      instance = klass.new(on_create: [{ transaction: [{ notify: { type: 'email', role: 'admin' } }] }])
      key_warnings = instance.config_warnings.select { |w| w[:message]&.match?(/unrecognized key|must be /) }
      expect(key_warnings).to be_empty
    end
  end

  # ── BatchTrigger ────────────────────────────────────────────────────

  describe OptionConfigs::ExtraOptionConfigs::BatchTrigger do
    let(:klass) { described_class }

    it 'surfaces a nested unrecognized trigger name warning from on_record' do
      instance = klass.new(on_record: [{ fake_trigger_xyz: { z: 1 } }])
      messages = instance.config_warnings.map { |w| w[:message].to_s }
      expect(messages.any? { |m| m.include?('fake_trigger_xyz') }).to be true
    end

    it 'surfaces a nested unrecognized inner key warning from on_record' do
      instance = klass.new(on_record: [{ create_reference: { ref1: { in: 'a_model', no_such_inner_key: true } } }])
      messages = instance.config_warnings.map { |w| w[:message].to_s }
      expect(messages.any? { |m| m.include?('no_such_inner_key') }).to be true
    end

    it 'tags propagated warnings with parent_attribute :on_record' do
      instance = klass.new(on_record: [{ phantom_action: {} }])
      tagged = instance.config_warnings.select { |w| w[:parent_attribute] == :on_record }
      expect(tagged).not_to be_empty
    end
  end

  # ── ConfigTrigger ───────────────────────────────────────────────────

  describe OptionConfigs::ExtraOptionConfigs::ConfigTrigger do
    let(:klass) { described_class }

    it 'surfaces a nested unrecognized trigger name warning from on_define' do
      instance = klass.new(on_define: [{ not_an_action: {} }])
      messages = instance.config_warnings.map { |w| w[:message].to_s }
      expect(messages.any? { |m| m.include?('not_an_action') }).to be true
    end

    it 'surfaces a nested unrecognized inner key warning from on_define' do
      instance = klass.new(on_define: [{ wrong_inner_key: { some_config: true } }])
      messages = instance.config_warnings.map { |w| w[:message].to_s }
      expect(messages.any? { |m| m.include?('wrong_inner_key') }).to be true
    end

    it 'tags propagated warnings with parent_attribute :on_define' do
      instance = klass.new(on_define: [{ phantom: {} }])
      tagged = instance.config_warnings.select { |w| w[:parent_attribute] == :on_define }
      expect(tagged).not_to be_empty
    end

    it 'does not surface warnings for valid on_define configurations' do
      instance = klass.new(on_define: [{ create_defaults: {} }])
      expect(instance.config_warnings).to be_empty
    end
  end
end
