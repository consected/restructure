# frozen_string_literal: true

# ApplicationHelper Spec
#
# Tests helper methods used across the application for view rendering and error handling.
#
# Test Coverage:
# - #remove_empty_error: Removes DoNotDisplayErrorMessage markers from validation errors
#   - Filters out DoNotDisplayErrorMessage markers while preserving valid error messages
#   - Removes entire error fields that contain only DoNotDisplayErrorMessage markers
#   - Ensures clean error display to users by eliminating internal marker constants

require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe '#remove_empty_error' do
    let(:user) { User.new }
    let(:errors) { user.errors }

    it 'removes errors with DoNotDisplayErrorMessage marker' do
      errors.add(:field1, 'Valid error')
      errors.add(:field2, ApplicationHelper::DoNotDisplayErrorMessage)
      errors.add(:field3, 'Another error')
      errors.add(:field3, ApplicationHelper::DoNotDisplayErrorMessage)

      helper.remove_empty_error(errors)

      expect(errors[:field1]).to include('Valid error')
      expect(errors[:field2]).to be_empty
      # Field3 should have "Another error" but not the empty DoNotDisplayErrorMessage
      expect(errors[:field3]).to include('Another error')
      # The empty string should have been removed
      expect(errors.messages[:field3]).not_to include('')
    end

    it 'removes only the field if it contains only DoNotDisplayErrorMessage' do
      errors.add(:terms_of_use_accepted, ApplicationHelper::DoNotDisplayErrorMessage)

      helper.remove_empty_error(errors)

      # The entire key should be removed
      expect(errors.messages.key?(:terms_of_use_accepted)).to be false
    end
  end
end
