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
RSpec.describe Dynamic::DefGenerator, type: :model do
  let(:dm) { DynamicModel.new }
  let(:missing_class_name) { 'NotARealDynamicClassXyz123' }

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
      allow(dm).to receive_messages(prefix_class: Object, full_implementation_class_name: missing_class_name)

      expect(dm.logger).not_to receive(:warn)

      dm.send(:remove_implementation_class)
    end
  end
end
