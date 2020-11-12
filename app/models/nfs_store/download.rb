# frozen_string_literal: true

module NfsStore
  class Download < MultiActions
    self.table_name = 'nfs_store_downloads'

    def item_actions_field
      'retrieved_items'
    end

    # Handle the retrieval of muliple requested files, returning an array of results
    # Each result is a hash referencing the requested id/retrieval_type
    # @param selected_items [Hash{id=>Integer, retrieval_type=>Symbol}] a hash of items to retrieve, with each ID qualified by a retrieval type
    # @return [Array(Hash{retrieval_type=>Symbol, id=>Integer, file_name=>String, container_path=>String, retrieval_path=>String})]
    #  id and retrieval_type match the requested item
    #  file_name is the simple file name
    #  container_path represents the local path within the container
    #  retrieval_path is the filesystem path from which the file can be retrieved
    def retrieve_files_from(selected_items)
      setup_items selected_items, :download

      self.zip_file_path = NfsStore::Archive::ZipFileGenerator.zip_retrieved_items all_action_items

      all_action_items
    end
  end
end
