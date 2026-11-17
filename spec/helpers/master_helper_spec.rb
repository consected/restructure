# frozen_string_literal: true

# Covers filtering configured master-result ID display to IDs the user can access.
require 'rails_helper'

RSpec.describe MasterHelper, type: :helper do
  describe '#master_result_id_list' do
    it 'keeps only accessible alternative IDs while preserving master_id' do
      user = instance_double(User)
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:app_config_items)
        .with(:show_ids_in_master_result, ['master_id'])
        .and_return(%w[master_id scantron_id sage_id])
      allow(Master).to receive(:alternative_id?) do |id, access_by:|
        id.to_sym == :scantron_id && access_by == user
      end

      expect(helper.master_result_id_list).to eq(%w[master_id scantron_id])
    end

    it 'preserves none and the default master_id list' do
      user = instance_double(User)
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:app_config_items)
        .with(:show_ids_in_master_result, ['master_id'])
        .and_return(['none'])

      expect(helper.master_result_id_list).to eq(['none'])

      allow(helper).to receive(:app_config_items)
        .with(:show_ids_in_master_result, ['master_id'])
        .and_return(['master_id'])

      expect(helper.master_result_id_list).to eq(['master_id'])
    end
  end
end
