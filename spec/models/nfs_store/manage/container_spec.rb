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

  it 'evaluates if specific actions can be performed for the container' do
    create_user
    finalize_al_setup activity: :evaluate_can_perform_if
    setup_access :send_files_to_trash, resource_type: :general, access: :read, user: @user
    setup_access :move_files, resource_type: :general, access: :read, user: @user
    setup_access :user_file_actions, resource_type: :general, access: nil, user: @user

    al_orig = @activity_log
    expect(al_orig.current_user).to eq @user

    cs = NfsStore::Manage::Container.last.reload
    cs.current_user = al_orig.current_user
    cs.parent_item = al_orig

    expect(cs.parent_item).to eq al_orig
    ac = al_orig.option_type_config.nfs_store&.dig(:can, :send_files_to_trash_if)
    expect(ac).to be_a Hash

    ac = al_orig.option_type_config.nfs_store&.dig(:can, :move_files_if)
    expect(ac).to be_a Hash

    ac = al_orig.option_type_config.nfs_store&.dig(:can, :download_files_if)
    expect(ac).to be nil

    # Initial checks to ensure the test setup is correct
    expect(@user.can?(:send_files_to_trash)).to be_truthy
    expect(@user.can?(:download_files)).to be_truthy
    expect(@user.can?(:move_files)).to be_truthy
    expect(@user.can?(:user_file_actions)).to be_falsey

    # Conditional evaluations will be false for the first two since the logic doesn't match,
    expect(cs.can_perform_if?(:send_files_to_trash)).to be false
    expect(cs.can_perform_if?(:move_files)).to be false
    # :no_config since there is no configuration for it
    expect(cs.can_perform_if?(:download_files)).to be :no_config
    # true since it is set to always: true
    expect(cs.can_perform_if?(:user_file_actions)).to be true

    al_orig.select_call_direction = nil
    expect(cs.can_edit?).to be true
    # Based on the conditional conditions...
    expect(cs.can_send_to_trash?).to be false
    expect(cs.can_move_files?).to be false
    # :no_config so evaluating can_edit?, which returns true
    expect(cs.can_download?).to be true
    # false since the UAC does not allow this action
    expect(cs.can_user_file_actions?).to be false

    # Reload, to clear the memoized results
    cs = NfsStore::Manage::Container.last.reload
    cs.current_user = al_orig.current_user
    cs.parent_item = al_orig

    al_orig.select_call_direction = 'to staff'
    expect(cs.can_edit?).to be true

    expect(cs.can_perform_if?(:send_files_to_trash)).to be true
    expect(cs.can_perform_if?(:move_files)).to be false
    # :no_config since there is no configuration for it
    expect(cs.can_perform_if?(:download_files)).to be :no_config
    # true since it is set to always: true
    expect(cs.can_perform_if?(:user_file_actions)).to be true

    # Based on the conditional conditions...
    expect(cs.can_send_to_trash?).to be true
    expect(cs.can_move_files?).to be false
    # :no_config so evaluating can_edit?, which returns true
    expect(cs.can_download?).to be true
    # false since the UAC does not allow this action
    expect(cs.can_user_file_actions?).to be false

    # Reload, to clear the memoized results
    cs = NfsStore::Manage::Container.last.reload
    cs.current_user = al_orig.current_user
    cs.parent_item = al_orig

    al_orig.select_call_direction = 'to player'
    expect(cs.can_edit?).to be true

    expect(cs.can_perform_if?(:send_files_to_trash)).to be false
    expect(cs.can_perform_if?(:move_files)).to be true
    # :no_config since there is no configuration for it
    expect(cs.can_perform_if?(:download_files)).to be :no_config
    # true since it is set to always: true
    expect(cs.can_perform_if?(:user_file_actions)).to be true

    # Based on the conditional conditions...
    expect(cs.can_send_to_trash?).to be false
    expect(cs.can_move_files?).to be true
    # :no_config so evaluating can_edit?, which returns true
    expect(cs.can_download?).to be true
    # false since the UAC does not allow this action
    expect(cs.can_user_file_actions?).to be false
  end
end
