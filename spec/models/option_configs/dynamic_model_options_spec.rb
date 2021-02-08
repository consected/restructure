# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

# Describe how dynamic model options work, especially with versioning
RSpec.describe 'Dynamic Model Options', type: :model do
  include MasterSupport
  include ModelSupport
  include PlayerContactSupport
  include BulkMsgSupport
  include DynamicModelSupport
  include OptionsSupport

  let :dynamic_type do
    DynamicModel::TestCreatedByRec
  end

  before :example do
    @user0, = create_user
    create_admin
    create_user
    setup_access :trackers
    setup_access :tracker_history
  end

  it 'gets the correct version of extra options based on creation date of the instance' do
    # NOTE: timestamps are compared after rounding down with .to_i to ensure that
    # the difference between the updated_at time generated by Rails and returned by the DB
    # do not cause unnecessary failures to be reported

    @def_updated_at = []
    @dyn_instances = []
    @option_texts = []
    @option_configs = []

    # Setup a simple dynamic model definition without any extra options
    dmdef = generate_test_dynamic_model
    @option_texts[1] = nil
    @def_updated_at[1] = dmdef.updated_at

    # The option_configs retrieved directly from the current definition are always the current version
    @option_configs[1] = dmdef.option_configs

    # Create an instance of the dynamic model (v1)
    sleep 2 # ensure there are no timing issues
    @dyn_instances[1] = @master.dynamic_model__test_created_by_recs.create! test1: 'abc'
    expect(@dyn_instances[1]).to be_a dynamic_type

    # The definition options should match the original
    expect(@dyn_instances[1].current_definition.options).to eq @option_texts[1]
    expect(@dyn_instances[1].current_definition.option_configs).to eq @option_configs[1]

    # The dynamic model instance should pull options that matches the original v1 options
    check_version 1

    # Define some new option text and use it to update the definition as v2
    sleep 2 # ensure there are no timing issues
    @option_texts[2] = <<~END_DEF
      default:
        caption_before:
          all_fields: show before all fields
          test2: has a caption before test2
    END_DEF
    dmdef.update!(options: @option_texts[2], current_admin: @admin)
    @def_updated_at[2] = dmdef.updated_at
    @option_configs[2] = dmdef.option_configs

    # The updated dynamic model should contain the new options
    dmdef.reload
    expect(dmdef.options).to eq @option_texts[2]
    expect(dmdef.option_configs).to eq @option_configs[2]

    # Create an instance of the dynamic model (v2)
    sleep 2 # ensure there are no timing issues
    @dyn_instances[2] = @master.dynamic_model__test_created_by_recs.create! test1: 'abc2'

    # The dynamic model instance should pull options that matches the original v1 options
    check_version 1

    # The new dynamic model instance should pull options text that matches the new v2 options text
    check_version 2

    # Define some new option text and use it to update the definition as v3
    sleep 2 # ensure there are no timing issues
    @option_texts[3] = <<~END_DEF
      default:
        caption_before:
          test2: has a caption before test2
          submit: new caption before submit
        labels:
          test1: test1 label
    END_DEF

    dmdef.update!(options: @option_texts[3], current_admin: @admin)
    @def_updated_at[3] = dmdef.updated_at
    @option_configs[3] = dmdef.option_configs

    # Create an instance of the dynamic model (v2)
    sleep 2 # ensure there are no timing issues
    @dyn_instances[3] = @master.dynamic_model__test_created_by_recs.create! test1: 'abc3'

    check_version 3
    check_version 1
    check_version 2
  end
end
