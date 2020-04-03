# frozen_string_literal: true

module NfsStore
  class UserFileAction < MultiActions
    self.table_name = 'nfs_store_user_file_actions'

    def item_actions_field
      'action_items'
    end

    # Handle the requested action for muliple requested files, returning an array of results
    # Each result is a hash referencing the requested id/retrieval_type
    # @param selected_items [Hash{id=>Integer, retrieval_type=>Symbol}] a hash of items to retrieve, with each ID qualified by a retrieval type
    # @return [Array(Hash{retrieval_type=>Symbol, id=>Integer, file_name=>String, container_path=>String, retrieval_path=>String})]
    #  id and retrieval_type match the requested item
    #  file_name is the simple file name
    #  container_path represents the local path within the container
    #  retrieval_path is the filesystem path from which the trashed file can be retrieved
    def perform_action(selected_items, action_id)
      self.action = action_id
      setup_items selected_items, :user_file_actions

      items = all_action_items.map { |i| i[:retrieved_file] }
      ph = NfsStore::Process::ProcessHandler.new(items, use_pipeline: { user_file_actions: action_id })
      raise FphsException, "User File Action #{action_id} does not have any jobs defined" if ph.job_list.empty?

      ph.run_all

      all_action_items
    end
  end
end
