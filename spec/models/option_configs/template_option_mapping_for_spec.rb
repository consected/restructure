# frozen_string_literal: true

# OptionConfigs::TemplateOptionMapping.mapping_for picks the mapping method for a model data type, so
# callers such as the edit form do not need their own dispatch. These specs check that each of the three
# definition types dispatches to its own mapping with the arguments passed through, and that any other
# type (including nil) has no mapping.

require 'rails_helper'

RSpec.describe OptionConfigs::TemplateOptionMapping, '.mapping_for', type: :model do
  let(:def_record) { double('definition') }
  let(:option_type_config) { double('option type config') }
  let(:current_user) { double('user') }
  let(:mapped) { { mapped: true } }

  {
    dynamic_model: :dynamic_model_mapping,
    activity_log: :activity_log_mapping,
    external_identifier: :external_identifier_mapping
  }.each do |model_data_type, mapping_method|
    it "dispatches #{model_data_type} to #{mapping_method}" do
      expect(described_class).to receive(mapping_method)
        .with(def_record, option_type_config, current_user).and_return(mapped)

      expect(described_class.mapping_for(model_data_type, def_record, option_type_config, current_user))
        .to eq mapped
    end
  end

  [nil, :player_info, :report, 'dynamic_model'].each do |model_data_type|
    it "returns nil for #{model_data_type.inspect}" do
      expect(described_class).not_to receive(:dynamic_model_mapping)
      expect(described_class).not_to receive(:activity_log_mapping)
      expect(described_class).not_to receive(:external_identifier_mapping)

      expect(described_class.mapping_for(model_data_type, def_record, option_type_config, current_user)).to be_nil
    end
  end
end
