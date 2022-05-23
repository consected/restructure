# frozen_string_literal: true

require 'rails_helper'
require './db/table_generators/dynamic_models_table'

RSpec.describe NfsStore::Manage::Container, type: :model do
  include DynamicModelSupport
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  def self.before_action(_arg)
    nil
  end
  include NfsStore::InNfsStoreContainer

  before :each do
    seed_database && ::ActivityLog.define_models

    setup_nfs_store
    generate_test_dynamic_model
    @activity_log = @container.parent_item
  end

  it 'creates a single container for the user, shared across activities and masters' do
    create_user
    create_item
    als = ActivityLog::PlayerContactPhone.where(extra_log_type: 'file_config_user_creator')
    expect(als.count).to eq 0

    cs = NfsStore::Manage::Container.last
    check_id = cs&.id

    finalize_al_setup activity: :file_config_user_creator

    al_orig = @activity_log
    # Uses the controller concern method to verify access
    activity_log_for_container_access
    expect(@activity_log).to eq al_orig

    als = ActivityLog::PlayerContactPhone.where(extra_log_type: 'file_config_user_creator').reload
    cs = NfsStore::Manage::Container.last.reload
    new_cs_id = cs.id

    expect(als.count).to eq 1
    expect(new_cs_id).to be > check_id

    create_item
    setup_container_and_al activity: :file_config_user_creator

    als = ActivityLog::PlayerContactPhone.where(extra_log_type: 'file_config_user_creator').reload
    cs = NfsStore::Manage::Container.last.reload
    new_cs_id = cs.id
    expect(als.count).to eq 2
    expect(als[0].master_id).not_to eq als[1].master_id
    expect(new_cs_id).to eq cs.id

    ac = als[0].option_type_config.nfs_store&.dig(:always_use_this_for_access_control)
    expect(ac).to be true

    ac = als[1].option_type_config.nfs_store&.dig(:always_use_this_for_access_control)
    expect(ac).to be true
  end
end
