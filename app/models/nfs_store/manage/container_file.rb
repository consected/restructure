module NfsStore
  module Manage

    # Abract class from which file metata that is stored in the database are subclassed
    class ContainerFile < UserBase

      TrashPath = '.trash'

      default_scope -> { where "path IS NULL OR path NOT LIKE '#{TrashPath}%' " }

      after_create :process_new_file
      after_save :reset_flags

      attr_accessor :prevent_processing, :valid_path_change

      self.abstract_class = true
      def self.no_master_association
        true
      end

      # include HandlesUserBase
      include UserHandler
      include HasCurrentUser

      validate :prevent_path_change
      validates :user_id, presence: true

      def self.resource_name
        "nfs_store__manage__containers"
      end


      def self.permitted_params
        super - [:id, :file_hash, :file_name, :content_type, :file_size, :path, :file_updated_at, :nfs_store_container_id, :nfs_store_stored_file_id, :archive_file, :last_process_name_run]
      end

      def self.readonly_params
        [:file_metadata]
      end

      def self.retrieval_type
        name.demodulize.underscore.to_sym
      end

      def self.no_downcase_attributes
        ['title', 'file_metadata']
      end

      def no_user_validation
        validating?
      end

      def data
        title || file_name
      end

      def resource_name
        self.class.resource_name
      end

      def allows_current_user_access_to? perform, with_options=nil
        super
      end

      def self.trash_path? path
        !!(path.split('/').select {|p| p == TrashPath}.first)
      end

      def as_json extras={}
        extras[:methods] ||= []
        extras[:methods] << :master_id
        super
      end


      # After creating a new container_file record we should process it.
      # This will kick off the processing loop
      def process_new_file
        return true if @prevent_processing
        ph = NfsStore::Process::ProcessHandler.new(self)
        ph.run_all

      end

      # Get the full file path in a role mount for a stored or archived file
      # This automatically handles the relative archive file mount path if it is needed
      def file_path_for role_name:
        Filesystem.nfs_store_path role_name, self.container, self.container_path(no_filename: true), self.file_name
      end

      # Move the file to a new path, and/or rename, changing the path and file_name stored in the record to match
      # @param new_path [String] the new container relative path to move the file to, or if null leave it at the current path (rename only)
      # @param new_file_name [String] the new file name, or leave it the same if nil (move, don't rename the actual file)
      # @return [true|false] successful rename / move
      def move_to new_path, new_file_name=nil
        res = false
        new_file_name ||= self.file_name
        current_user_role_names.each do |role_name|
          curr_path = file_path_for role_name: role_name
          if File.exist?(curr_path)
            self.path = new_path if new_path
            self.file_name = new_file_name
            self.valid_path_change = true

            transaction do
              move_from curr_path
              save!
              res = true
            end
            break
          end
        end

        raise FsException::Action.new "Failed to move file to #{new_path}/#{new_file_name}" unless res
        res
      end

      # Move all stored or archived files in the specified from_path to the new to_path
      # @param in_container [NfsStore::Manage::Container]
      # @param from_path [String]
      # @param to_path [String]
      # @return [Integer] Number of files moved
      def self.move_folder in_container, from_path, to_path

        moved = 0

        files = in_container.stored_files.where(path: from_path)

        files.each do |f|
          res = f.move_to to_path
          moved += 1 if res
        end

        files = in_container.archived_files.where(path: from_path)

        files.each do |f|
          res = NfsStore::Archive::Mounter.move_to_new_path f, to_path
          moved += 1 if res
        end

        moved

      end

      # Move the file to trash
      # Create a .trash/stored_file_name directory
      # Then move the file appended with the current timestamp
      # If the file is an archive, remove any directories that are empty
      def move_to_trash!

        curr_path = nil
        current_user_role_names.each do |role_name|
          curr_path = file_path_for role_name: role_name
          break if File.exist?(curr_path)
        end

        f_path = self.container_path(no_filename: true)
        new_path = f_path.blank? ? TrashPath : File.join(TrashPath, f_path)
        dt = DateTime.now.to_i
        new_file_name = "#{self.file_name}--#{dt}"
        move_to new_path, new_file_name

        if curr_path && self.is_a?(ArchivedFile)
           NfsStore::Archive::Mounter.remove_empty_archive_dir(curr_path)
        end

      end


      # Move the file to its final location
      # @param from_path [String] the temporary path to move the file from
      # @return [Boolean] true if the file was moved successfully
      def move_from from_path

        res = false
        current_user_role_names.each do |role_name|

          if Filesystem.test_dir role_name, self.container, :write

            # If a path is set, ensure we can make a directory for it if one doesn't exist
            if !self.path.present? || Filesystem.test_dir(role_name, self.container, :mkdir, extra_path: self.container_path(no_filename: true), ok_if_exists: true)

              cleanpath = Filesystem.clean_path(self.path)
              if cleanpath
                is_trash_path = self.class.trash_path?(cleanpath)

                if !is_trash_path && (cleanpath.start_with?('.') || cleanpath.start_with?('/'))
                  raise FsException::Action.new "Path to move to is bad: #{cleanpath}"
                end
              end

              if is_trash_path
                to_path = cleanpath
              else
                to_path = self.container_path(no_filename: true)
              end

              res = Filesystem.move_file_to_final_location role_name, from_path, self.container, to_path, self.file_name
              break if res
            end
          end

        end

        raise FsException::NoAccess.new "User does not have permission to store file with any of the current groups" unless res
        true
      end

      private

        def reset_flags
          self.valid_path_change = false
        end

        def prevent_path_change
          if persisted?
            errors.add :path, "must not be changed" if !valid_path_change && self.path_changed?
          end
        end

    end
  end
end
