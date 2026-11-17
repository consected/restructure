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
      return if full_path&.strip.blank?

      path_parts = full_path.split('/').reject(&:blank?)
      pp_length = path_parts.length == 1
      file_name = path_parts.last
      file_path = path_parts[0..-2] unless pp_length

      res = container.stored_files.find_by(path: file_path, file_name: file_name)
      return res if res || pp_length

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
    # A single requested file is not zipped; use #single_file? with #single_file_path and #single_file_name
    # @param selected_items [Hash{id=>Integer, retrieval_type=>Symbol}] items keyed by ID and retrieval type
    # @param zip [Boolean] whether to create the synchronous archive for multi-file selections
    # @return [Array(Hash{retrieval_type=>Symbol, id=>Integer, file_name=>String, container_path=>String, retrieval_path=>String})]
    #  id and retrieval_type match the requested item
    #  file_name is the simple file name
    #  container_path represents the local path within the container
    #  retrieval_path is the filesystem path from which the file can be retrieved
    def retrieve_files_from(selected_items, zip: true)
      setup_items selected_items, :download

      if zip && !single_file?
        self.zip_file_path = NfsStore::Archive::ZipFileGenerator.zip_retrieved_items all_action_items
      end

      all_action_items
    end

    # Keep selections at the configured boundary synchronous; exceed either limit to defer zipping.
    # @return [Boolean]
    def background_required?
      return false if single_file?

      items = all_action_items || []
      items.length > self.class.background_download_max_files ||
        items.sum { |item| item[:file_size].to_i } > self.class.background_download_max_bytes
    end

    def self.background_download_max_files
      Settings::NfsStoreBackgroundDownloadMaxFiles
    end

    def self.background_download_max_bytes
      Settings::NfsStoreBackgroundDownloadMaxBytes
    end

    # @return [True, False] true if exactly one item has been retrieved, so it can be sent without zipping
    def single_file?
      all_action_items&.length == 1
    end

    # @return [String, nil] filesystem path of the single retrieved file
    def single_file_path
      single_file_item&.dig(:retrieval_path)
    end

    # @return [String, nil] file name of the single retrieved file
    def single_file_name
      single_file_item&.dig(:file_name)
    end

    private

    def single_file_item
      all_action_items.first if single_file?
    end
  end
end
