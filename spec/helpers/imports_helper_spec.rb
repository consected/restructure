# frozen_string_literal: true

# ImportsHelper Spec
#
# Validates helper behavior used by CSV import views to generate actionable
# field mismatch messages.

require 'rails_helper'

RSpec.describe ImportsHelper, type: :helper do
  describe '#unmatched_import_field_error' do
    it 'includes the field name and does not rely on object inspect output' do
      message = helper.unmatched_import_field_error('dynamic_model__test_recs_attributes[0]')

      expect(message).to include('dynamic_model__test_recs_attributes[0]')
      expect(message).to include('was not matched')
      expect(message).to include('model is up to date')
    end

    it 'extracts a readable field name from nested form object names' do
      message = helper.unmatched_import_field_error('imports_import[dynamic_model__test_labels]')

      expect(message).to include('dynamic_model__test_labels')
      expect(message).not_to include('imports_import[')
      expect(message).not_to include('] was not matched')
    end
  end
end
