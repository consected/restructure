# frozen_string_literal: true

require 'rails_helper'

# Covers Dynamic::DefGenerator#implementation_class_defined? logging behavior.
#
# Background: "Failed to get the class X in parent Y: uninitialized constant X" was being logged at
# WARN level on every server boot / code reload for every dynamic definition (ExternalIdentifier,
# DynamicModel, ActivityLog) associated with the active app types, even though the class simply had
# not been generated yet in this process. This happens because `remove_implementation_class` and
# `remove_assoc_class` call `implementation_class_defined?` purely to check whether an old class
# exists so it can be removed before regeneration - a missing class in that context is expected and
# routine, not a failure.
#
# These specs confirm:
# - By default, a genuinely missing class is still logged at WARN (callers that expect the class to
#   already exist, e.g. Dynamic::DefGenerator.enable_active_configurations/refresh_outdated, are
#   unaffected and continue to surface real problems).
# - When the caller passes `not_found_ok: true` (as the pre-generation cleanup checks now do), the
#   same missing-class condition is logged at DEBUG instead, since it is an expected, harmless outcome.
# - Class removal checks the exact namespace it removes and does not instantiate generated classes.
RSpec.describe Dynamic::DefGenerator, type: :model do
  include ModelSupport

  let(:dm) { DynamicModel.new }
  let(:missing_class_name) { 'NotARealDynamicClassXyz123' }
  let(:test_class_name) { 'CopilotIssue1520RemovalProbe' }

  describe '#implementation_class_defined?' do
    it 'logs at warn level by default when the class cannot be found' do
      expect(dm.logger).to receive(:warn).with(/Failed to get the class #{missing_class_name}/)
      expect(dm.logger).not_to receive(:debug)

      res = dm.implementation_class_defined?(Object, class_name: missing_class_name)
      expect(res).to be false
    end

    it 'logs at debug level (not warn) when not_found_ok is set' do
      expect(dm.logger).to receive(:debug).with(/Failed to get the class #{missing_class_name}/)
      expect(dm.logger).not_to receive(:warn)

      res = dm.implementation_class_defined?(Object, class_name: missing_class_name, not_found_ok: true)
      expect(res).to be false
    end
  end

  describe '#remove_implementation_class' do
    it 'does not warn when there is no existing class to remove' do
      allow(dm).to receive_messages(
        prefix_class: Object,
        model_class_name: test_class_name,
        full_implementation_class_name: "DynamicModel::#{test_class_name}"
      )

      expect(dm).not_to receive(:implementation_class_defined?)
      expect(dm.logger).not_to receive(:warn)

      expect { dm.send(:remove_implementation_class) }.not_to raise_error
      expect(Object.const_defined?(test_class_name, false)).to be false
    end

    it 'removes an existing class without instantiating it' do
      implementation = Class.new
      namespace = Module.new
      namespace.const_set(test_class_name, implementation)
      expect(dm).not_to receive(:implementation_class_defined?)
      expect(implementation).not_to receive(:new)
      allow(dm).to receive_messages(
        prefix_class: namespace,
        model_class_name: test_class_name,
        full_implementation_class_name: test_class_name,
        table_or_view_ready?: true
      )

      dm.send(:remove_implementation_class)

      expect(namespace.const_defined?(test_class_name, false)).to be false
    end

    it 'removes only the top-level constant when Object is the removal prefix' do
      expect(DynamicModel.const_defined?(test_class_name, false)).to be false
      Object.const_set(test_class_name, Class.new)
      allow(dm).to receive_messages(
        model_class_name: test_class_name,
        full_implementation_class_name: "DynamicModel::#{test_class_name}"
      )

      begin
        dm.send(:remove_implementation_class, Object)

        expect(Object.const_defined?(test_class_name, false)).to be false
      ensure
        Object.send(:remove_const, test_class_name) if Object.const_defined?(test_class_name, false)
      end
    end

    it 'does not treat a namespaced class as the top-level alias' do
      implementation = Class.new
      instantiation_count = 0
      stub_const("DynamicModel::#{test_class_name}", implementation)
      allow(implementation).to receive(:new) { instantiation_count += 1 }
      allow(dm).to receive_messages(
        model_class_name: test_class_name,
        full_implementation_class_name: "DynamicModel::#{test_class_name}"
      )

      dm.send(:remove_implementation_class, Object)

      expect(instantiation_count).to eq 0
      expect(DynamicModel.const_defined?(test_class_name, false)).to be true
    end
  end

  describe 'DynamicModel class regeneration' do
    before(:all) do
      change_setting('AllowDynamicMigrations', true)
      create_admin
      suffix = SecureRandom.hex(4).sub(/\A\d/, 'a')
      @definition = DynamicModel.create!(
        current_admin: @admin,
        name: "issue 1520 removal #{suffix}",
        table_name: "issue1520_removal_#{suffix}_records",
        schema_name: 'dynamic_test',
        category: :test
      )
      @definition_id = @definition.id
    end

    after(:all) do
      if @definition_id
        @definition = DynamicModel.find_by(id: @definition_id)
        if @definition
          @definition.reload.disable!(@admin)
          [DynamicModel, Object].each do |namespace|
            next unless namespace.const_defined?(@definition.model_class_name, false)

            namespace.send(:remove_const, @definition.model_class_name)
          end
        end
      end
      change_setting('AllowDynamicMigrations', false)
    end

    before do
      @definition = DynamicModel.find(@definition_id)
    end

    it 'replaces both aliases without instantiating the old or new implementation class' do
      old_implementation = @definition.implementation_class
      expect(DynamicModel.const_get(@definition.model_class_name, false)).to equal old_implementation
      expect(Object.const_get(@definition.model_class_name, false)).to equal old_implementation

      expect(@definition).not_to receive(:implementation_class_defined?)
      expect(old_implementation).not_to receive(:new)
      allow(DynamicModel).to receive(:const_set).and_wrap_original do |original, constant_name, value|
        result = original.call(constant_name, value)
        expect(result).not_to receive(:new) if constant_name.to_s == @definition.model_class_name
        result
      end

      @definition.force_regenerate = true
      @definition.generate_model
      new_implementation = @definition.implementation_class

      expect(new_implementation).not_to equal old_implementation
      expect(DynamicModel.const_get(@definition.model_class_name, false)).to equal new_implementation
      expect(Object.const_get(@definition.model_class_name, false)).to equal new_implementation
    end
  end
end
