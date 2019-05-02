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


      def move_to new_path, new_file_name=nil
        res = false
        new_file_name ||= self.file_name
        current_user_role_names.each do |role_name|
          curr_path = Filesystem.nfs_store_path role_name, self.container, self.container_path(no_filename: true), self.file_name
          if File.exist?(curr_path)
            self.path = new_path
            self.file_name = new_file_name
            self.valid_path_change = true
            transaction do
              move_from curr_path
              save!
              res = true
              break
            end
          end
        end

        raise FsException::Action.new "Failed to move file to #{new_path}/#{new_file_name}" unless res
        res
      end

      def move_to_trash!
        sf_path = self.container_path(no_filename: true)
        new_path = sf_path.blank? ? TrashPath : File.join(TrashPath, sf_path)
        move_to new_path

        if respond_to? :archived_files
          archived_files.each do |af|
            af.current_user = self.current_user

            path_parts = []
            path_parts << TrashPath
            path_parts << af.container_path(no_filename: true)
            new_path = File.join path_parts
            af.move_to new_path
          end
        end
      end


      # Move the file it its final location
      # @param from_path [String] the temporary path to move the file from
      # @return [Boolean] true if the file was moved successfully
      def move_from from_path

        res = false
        current_user_role_names.each do |role_name|

          if Filesystem.test_dir role_name, self.container, :write

            # If a path is set, ensure we can make a directory for it if one doesn't exist
            if !self.path.present? || Filesystem.test_dir(role_name, self.container, :mkdir, extra_path: self.path, ok_if_exists: true)
              res = Filesystem.move_file_to_final_location role_name, from_path, self.container, self.path, self.file_name
              break if res
            end
          end

        end

        raise FsException::NoAccess.new "User does not have permission to store file with any of the current groups" unless res
        true
      end

      private

        def reset_flags
          valid_path_change = false
        end

        def prevent_path_change
          if persisted?
            errors.add :path, "must not be changed" if !valid_path_change && self.path_changed?
          end
        end

    end
  end
end
