module NfsStore
  class Trash < MultiActions

    self.table_name = 'nfs_store_trash_actions'

    def item_actions_field
      "trashed_items"
    end


    # Handle the trash of muliple requested files, returning an array of results
    # Each result is a hash referencing the requested id/retrieval_type
    # @param selected_items [Hash{id=>Integer, retrieval_type=>Symbol}] a hash of items to retrieve, with each ID qualified by a retrieval type
    # @return [Array(Hash{retrieval_type=>Symbol, id=>Integer, file_name=>String, container_path=>String, retrieval_path=>String})]
    #  id and retrieval_type match the requested item
    #  file_name is the simple file name
    #  container_path represents the local path within the container
    #  retrieval_path is the filesystem path from which the trashed file can be retrieved
    def trash_all selected_items

      # Retrieve each file's details. The container_id will be passed if this is a
      # multi container download, otherwise it will be ignored
      selected_items.each do |s|
        container = self.container || Browse.open_container(id: s[:container_id], user: self.current_user)
        activity_log = self.activity_log || ActivityLog.open_activity_log(s[:activity_log_type], s[:activity_log_id], self.current_user)
        retrieve_file_from(s[:id], s[:retrieval_type], container: container, activity_log: activity_log)
      end


      self.all_action_items.each do |item|
        item[:retrieved_file].move_to_trash!
      end

      self.all_action_items
    end

  end
end
