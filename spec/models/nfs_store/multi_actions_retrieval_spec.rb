# frozen_string_literal: true

# Regression coverage for issue #1493: inaccessible files raise NotFound during retrieval.

require 'rails_helper'

RSpec.describe NfsStore::Download, type: :model do
  it 'raises NotFound when the retrieved file has no accessible retrieval path' do
    activity_log = instance_double(ActivityLog)
    container = instance_double(
      NfsStore::Manage::Container,
      parent_item: activity_log,
      raise_if_no_access!: true,
      raise_if_action_not_authorized!: true,
      raise_if_no_activity_log_specified!: true
    )
    retrieved_file = instance_double(
      NfsStore::Manage::StoredFile,
      id: 1,
      current_user_group_ids: [600],
      container: container,
      file_name: 'inaccessible.txt',
      retrieval_path: nil,
      file_metadata: {}
    )
    user = instance_double(User)
    download = described_class.new

    allow(download).to receive(:container).and_return(container)
    allow(download).to receive(:activity_log).and_return(activity_log)
    allow(download).to receive(:current_user).and_return(user)
    allow(download).to receive(:filtered_files_as_scopes).with(activity_log).and_return(
      stored_files: [retrieved_file], archived_files: []
    )
    allow(download).to receive(:user_groups=)
    allow(download).to receive(:container=)
    allow(download).to receive(:user=)
    allow(download).to receive(:retrieval_path=)

    expect do
      download.retrieve_file_from(1, :stored_file, for_action: :download)
    end.to raise_error(FsException::NotFound, 'file not found with available group access')
  end

  it 'raises NotFound before queuing an inaccessible item in a multi-item move action' do
    activity_log = instance_double(ActivityLog)
    container = instance_double(
      NfsStore::Manage::Container,
      parent_item: activity_log,
      raise_if_no_access!: true,
      raise_if_action_not_authorized!: true,
      raise_if_no_activity_log_specified!: true
    )
    retrieved_file = instance_double(
      NfsStore::Manage::StoredFile,
      id: 1,
      current_user_group_ids: [600],
      container: container,
      file_name: 'inaccessible.txt',
      retrieval_path: nil,
      file_metadata: {}
    )
    move_action = NfsStore::MoveAndRename.new multiple_items: true

    allow(move_action).to receive(:filtered_files_as_scopes).with(activity_log).and_return(
      stored_files: [retrieved_file], archived_files: []
    )
    allow(move_action).to receive(:current_user).and_return(instance_double(User))
    allow(move_action).to receive(:user_groups=)
    allow(move_action).to receive(:container=)
    allow(move_action).to receive(:user=)

    expect do
      move_action.retrieve_file_from(
        1, :stored_file,
        for_action: :move_files,
        container: container,
        activity_log: activity_log
      )
    end.to raise_error(FsException::NotFound, 'file not found with available group access')
  end
end
