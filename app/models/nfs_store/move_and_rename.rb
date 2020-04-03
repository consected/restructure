# frozen_string_literal: true

module NfsStore
  class MoveAndRename < MultiActions
    self.table_name = 'nfs_store_move_actions'

    def item_actions_field
      'moved_items'
    end

    # Move requested files to a new path, returning an array of results
    # Each result is a hash referencing the requested id/retrieval_type
    # @param selected_items [Hash{id=>Integer, retrieval_type=>Symbol}] a hash of items to retrieve, with each ID qualified by a retrieval type
    # @param new_path [String] new path to move to
    # @return [Array(Hash{retrieval_type=>Symbol, id=>Integer, file_name=>String, container_path=>String, retrieval_path=>String})]
    #  id and retrieval_type match the requested item
    #  file_name is the simple file name
    #  container_path represents the local path within the container
    #  retrieval_path is the filesystem path from which the moved file can be retrieved
    def move_files(selected_items, new_path)
      new_path = Manage::Filesystem.clean_path new_path

      setup_items selected_items, :move_files

      if new_path && (new_path.start_with?('.') || new_path.start_with?('/'))
        raise FsException::Action, "Path to move to can not start with / or .: #{new_path}"
      end

      # Find the depth of the highest path we are planning to move, so we can use this as the root of sub directories to move
      # Otherwise all files, including those in sub directories get dumped directly in the new path
      all_paths = all_action_items.map { |item| item[:retrieved_file].path }.uniq.sort
      top_path = all_paths.first
      second_path = all_paths[1]
      top_paths = all_paths.map { |f| f && f.split('/').compact.first }.uniq

      if top_paths.length > 1
        raise FsException::Action, "Files and folders to move must all be in the same base path. Specified base paths are #{top_paths.join(', ')}"
      end

      # If we have multiple paths and more than one of the initial ones is at the same depth
      # (for example, two or more sub directories)
      # then the top_path is actually a level up

      if top_path && second_path && second_path.split('/').length == top_path.split('/').length
        top_path = top_path.sub(%r{[^/]+$}, '').sub(%r{/$}, '')
      end

      all_action_items.each do |item|
        rf = item[:retrieved_file]
        # Replace the top path with the new path, allowing relative moves of sub directories
        # Handle blank top paths carefully
        rf.path = "/#{rf.path}" if top_path.blank?
        rf.path = "#{rf.path}/"
        new_item_path = rf.path.sub(%r{^#{top_path}/}, "#{new_path}/").gsub(%r{(^/+|/+$)}, '')
        rf.move_to new_item_path
      end

      self.new_path = new_path

      all_action_items
    end

    # Rename requested file, returning an array of results
    # Each result is a hash referencing the requested id/retrieval_type
    # @param selected_items [Hash{id=>Integer, retrieval_type=>Symbol}] a hash of items to retrieve, with each ID qualified by a retrieval type
    # @param new_anme [String] new name to give the file
    # @return [Array(Hash{retrieval_type=>Symbol, id=>Integer, file_name=>String, container_path=>String, retrieval_path=>String})]
    #  id and retrieval_type match the requested item
    #  file_name is the simple file name
    #  container_path represents the local path within the container
    #  retrieval_path is the filesystem path from which the moved file can be retrieved
    def rename_file(selected_items, new_name)
      raise FsException::Action, 'New name is not specified' if new_name.blank?

      setup_items selected_items, :move_files

      all_action_items.each do |item|
        f = item[:retrieved_file]
        archive_file = f.archive_file if f.respond_to? :archive_file
        unless filters_allow_rename?(archive_file, f.path, new_name)
          raise FsException::Action, "New name is not allowed. Check it meets the requirements of the 'valid upload files' list"
        end

        f.move_to nil, new_name
      end

      self.new_path = new_path

      all_action_items
    end

    protected

    def filters_allow_rename?(archive_file, path, new_name)
      f = [archive_file, path, new_name].join('/').gsub(%r{//+}, '/')
      f = "/#{f}" unless f.start_with? '/'
      NfsStore::Filter::Filter.evaluate f, activity_log
    end
  end
end
