# frozen_string_literal: true

# These tests lock down the Study Recruitment initial-call dynamic-model
# configuration so reused setup state gets rebuilt when it still references
# the legacy select_* field names.

require 'rails_helper'

describe StudyRecruitmentSetup do
  describe '.stale_initial_call_dynamic_model_config?' do
    let(:dynamic_model) do
      instance_double(DynamicModel, field_list: field_list, options: options)
    end

    context 'when the initial-call config still uses legacy select-prefixed fields' do
      let(:field_list) { 'select_still_interested select_continue_now callback_date callback_time notes' }
      let(:options) { 'select_still_interested:\nselect_continue_now:' }

      it 'treats the config as stale' do
        expect(described_class.stale_initial_call_dynamic_model_config?(dynamic_model)).to be true
      end
    end

    context 'when the initial-call config uses the current field names' do
      let(:field_list) { 'still_interested continue_now callback_date callback_time notes' }
      let(:options) { 'still_interested:\ncontinue_now:' }

      it 'treats the config as current' do
        expect(described_class.stale_initial_call_dynamic_model_config?(dynamic_model)).to be false
      end
    end
  end
end
