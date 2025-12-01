# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Describe how dynamic model options work, especially with versioning
RSpec.describe 'Dynamic Model Options', type: :model do
  include MasterSupport
  include ModelSupport
  include DynamicModelSupport
  include OptionsSupport
  include TestOptionTypesDmSupport

  describe 'option types' do
    before(:example) do
      create_admin
      create_user
      @resource_name = :dynamic_model__test_multi_options
      setup_multi_option_types_dm

      setup_access :trackers
      setup_access :tracker_histories
      setup_access @resource_name, user: @user, app_type: @app_type
      expect(@user.has_access_to?(:create, :table, @resource_name)).to be_truthy
      Rails.application.routes_reloader.reload!
    end

    it 'tests the setup of multiple option types with defaults and configurations' do
      dm_def = DynamicModel::TestMultiOption.definition
      expect(dm_def.configurations[:use_current_version]).to be true
      expect(dm_def.configurations[:option_type_attr_name]).to eq 'option_type'
      expect(dm_def.option_type_config_for(:test_defaults_only).view_options).to eq(data_attribute: 'field_1')
      expect(dm_def.option_type_config_for(:test_defaults_only).field_options).to eq(field_1: { no_downcase: true })
      expect(dm_def.option_type_config_for(:test_defaults_only).labels).to eq(field_1: 'Field 1 Label', field_2: 'Field 2 Label', field_3: 'Field 3 Label', field_4: 'Field 4 Label', field_5: 'Field 5 Label', option_type: 'View Type')
    end
  end
end
