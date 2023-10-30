# frozen_string_literal: true

require 'rails_helper'

# Dig into the internals of the NfsStore::InNfsStoreContainer concern to
# check it is able to find the container and activity log based on
# various permutations it may be called with
RSpec.describe NfsStore::InNfsStoreContainer, type: :controller do
  include PlayerContactSupport
  include ModelSupport
  include NfsStoreSupport

  def self.before_action(_arg)
    nil
  end

  def secure_params
    @params
  end

  def current_user
    @user
  end

  attr_reader :params

  include NfsStore::InNfsStoreContainer

  before :each do
    seed_database && ::ActivityLog.define_models

    setup_nfs_store
    create_item
    setup_container_and_al
    @orig_activity_log = @container.parent_item
    @activity_log = nil
    @container = nil
  end

  it 'finds a container with associated activity log by id' do
    cs = NfsStore::Manage::Container.last
    check_id = cs&.id

    expect(check_id).not_to be nil

    @params = {
      activity_log_id: @orig_activity_log.id,
      activity_log_type: 'activity_log__player_contact_phone',
      id: check_id
    }

    send(:find_container)

    expect(@activity_log.id).to eq @orig_activity_log.id
    expect(@container.id).to eq check_id
  end

  it 'finds a container alone if no activity log is specified' do
    cs = NfsStore::Manage::Container.last
    check_id = cs&.id

    expect(check_id).not_to be nil

    @params = {
      id: check_id
    }

    send(:find_container)

    expect(@container.id).to eq check_id
    expect(@activity_log).to be nil
  end

  it 'finds an activity log and no container if not told to find the default from the activity log' do
    cs = NfsStore::Manage::Container.last
    check_id = cs&.id

    expect(check_id).not_to be nil

    @params = {
      activity_log_id: @orig_activity_log.id,
      activity_log_type: 'activity_log__player_contact_phone'
    }

    expect { send(:find_container) }.to raise_error(FsException::Action, 'container id must be set')

    expect(@container).to be nil
    expect(@activity_log.id).to eq @orig_activity_log.id
  end

  it 'finds an activity log and its default container if told to find the container from the activity log' do
    cs = NfsStore::Manage::Container.last
    check_id = cs&.id

    expect(check_id).not_to be nil

    @set_container_from_activity_log = true

    @params = {
      activity_log_id: @orig_activity_log.id,
      activity_log_type: 'activity_log__player_contact_phone'
    }

    send(:find_container)

    expect(@container.id).to eq check_id
    expect(@activity_log.id).to eq @orig_activity_log.id
  end

  it 'finds an activity log and its default container based on an activity log secondary key' do
    cs = NfsStore::Manage::Container.last
    check_id = cs&.id

    expect(check_id).not_to be nil

    @set_container_from_activity_log = true

    ActivityLog::PlayerContactPhone.definition.configurations = { secondary_key: 'data' }

    @params = {
      activity_log_id: @orig_activity_log.data,
      activity_log_type: 'activity_log__player_contact_phone'
    }

    send(:find_container)

    expect(@container.id).to eq check_id
    expect(@activity_log.id).to eq @orig_activity_log.id
  end
end
