# frozen_string_literal: true

module NfsStore
  class Download < MultiActions
    self.table_name = 'nfs_store_downloads'

    def item_actions_field
      'retrieved_items'
    end

    #
    # Find a download file by path, returning a the ContainerFile
    # This allows theretrieval type and the download id to be easily accessed
    # if the file is found.
    # Leading slash and double slash will be ignored
    # @param [NfsStore::Manage::Container] container
    # @param [String] full_path
    # @return [NfsStore::Manage::ContainerFile]
    def self.find_download_by_path(container, full_path)
      return if full_path.strip.blank?

      path_parts = full_path.split('/').reject(&:blank?)
      pp_length = path_parts.length == 1
      file_name = path_parts.last
      file_path = path_parts[0..-2] unless pp_length

      res = container.stored_files.find_by(path: file_path, file_name: file_name)
      return res if res || pp_length == 1

      archive_file = file_path.first
      file_path = if file_path.length == 1
                    ''
                  else
                    file_path[1..]
                  end
      res = container.archived_files.find_by(path: file_path, archive_file: archive_file, file_name: file_name)
      return res if res
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
