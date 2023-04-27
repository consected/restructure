# frozen_string_literal: true

module NfsStore
  module Manage
    # Abract class from which file metata that is stored in the database are subclassed
    class ContainerFile < UserBase
      TrashPath = '.trash'

      default_scope -> { where "path IS NULL OR path NOT LIKE '#{TrashPath}%' " }

      after_create :process_new_file, unless: -> { do_not_postprocess }
      after_save :reset_flags

      attr_accessor :prevent_processing, :valid_path_change, :do_not_postprocess

      self.abstract_class = true
      def self.no_master_association
        true
      end

      # include HandlesUserBase
      include UserHandler
      include HasCurrentUser
      include Dynamic::DefHandler
      include Dynamic::ModelReferenceHandler
      include Dynamic::ImplementationHandler

      validate :prevent_path_change
      validates :user_id, presence: true

      def self.resource_name
        'nfs_store__manage__containers'
      end

      def self.short_type
        name.split('::').last.ns_underscore.to_sym
      end

      def implementation_model_name
        self.class.name.split('::').last
      end

      def disabled
        return attributes['disabled'] if attributes.key?('disabled')

        false
      end

      def disabled?
        !!disabled
      end

      def saved_change_to_disabled?
        false
      end

      def self.implementation_prefix
        'NfsStore::Manage'
      end

      def self.category
        :nfs_store
      end

      def self.permitted_params
        super - %i[id file_hash file_name content_type file_size path file_updated_at
                   nfs_store_container_id nfs_store_stored_file_id archive_file
                   last_process_name_run]
      end

      def self.readonly_params
        [:file_metadata]
      end

      def self.retrieval_type
        @retrieval_type ||= name.demodulize.underscore.to_sym
      end

      def self.no_downcase_attributes
        %w[title file_metadata]
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

      def allows_current_user_access_to?(perform, with_options = nil)
        super
      end

      def self.trash_path?(path)
        !!path.split('/').select { |p| p == TrashPath }.first
      end

      # Shortcut way to check if a file is a compressed archive
      # @return [Boolean] true if the file is an archive
      def is_archive?
        NfsStore::Archive::Mounter.has_archive_extension? self
      end

      #
      # Calculate the new path for a file moved to trash
      # @return [<Type>] <description>
      def trash_path
        f_path = container_path(no_filename: true)
        f_path.blank? ? TrashPath : File.join(TrashPath, f_path)
      end

      def retrieval_type
        self.class.retrieval_type
      end

      def container_dir_path
        container_path(no_filename: true, leading_dot: true)
      end

      def container_parent
        cpi = container&.parent_item
        return unless cpi

        {
          activity_log_id: cpi.id,
          activity_log_type: cpi.item_type
        }
      end

      def as_json(extras = {})
        lr = extras.delete(:limited_results)
        extras[:methods] ||= []
        extras[:methods] << :container_parent
        extras[:methods] << :direct_uri if !lr || container&.show_file_links_as_path
        return super unless lr

        allow_show_flags = extras.delete(:allow_show_flags)

        extras[:include] ||= []
        extras[:methods] << :retrieval_type
        extras[:methods] << :mime_type_text
        extras[:methods] << :file_metadata_present
        extras[:include] << :item_flags if allow_show_flags && allow_show_flags[retrieval_type]
        # Call serializable_hash rather than super, to avoid GeneralDataConcerns processing more than we need
        serializable_hash(extras)
      end

      # Store a new file from a temp file, into a container, with a full set of attributes
      # The attributes can come from a copy of an existing container_file, with container_file.attributes
      #
      # @param [String] new_tmp_image_path is the path to the file to move to the final storage
      # @param [Container] container
      # @param [Hash] attrs full set of attributes. Unnecessary items will be overwritten.
      # @option attrs [String] path
      # @option attrs [String] file_name
      # @option attrs [String] content_type - (optional) will be detected automatically if not set
      # @option attrs [String] archived_file_path - (optional) for archived files
      # @option attrs [Boolean] do_not_postprocess - (optional) true to prevent
      #     background processing pipeline from running
      # @return [NfsStore::Manage::ContainerFile] new container_file
      #
      def self.store_new_file(new_tmp_image_path, container, attrs)
        container_file = new(attrs)
        container_file.id = nil
        container_file.container = container
        container_file.current_user = container.current_user
        container_file.file_hash = container_file.class.hash_for_file(new_tmp_image_path)

        container_file.move_from new_tmp_image_path
        container_file.analyze_file!
        container_file.valid_path_change = true
        container_file.save!
        container_file
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
      def file_path_for(role_name:)
        Filesystem.nfs_store_path role_name, container, container_path(no_filename: true), file_name
      end

      # Move the file to a new path, and/or rename, changing the path and file_name stored in the record to match
      # @param [String] new_path the new container relative path to move the file to, or if null leave it at the current path (rename only)
      # @param [String] new_file_name the new file name, or leave it the same if nil (move, don't rename the actual file)
      # @return [true|false] successful rename / move
      def move_to(new_path, new_file_name = nil)
        res = false
        new_file_name ||= file_name
        current_user_role_names.each do |role_name|
          curr_path = file_path_for role_name: role_name
          next unless File.exist?(curr_path)

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

        raise FsException::Action, "Failed to move file to #{new_path}/#{new_file_name}" unless res

        res
      end

      # Move all stored or archived files in the specified from_path to the new to_path
      # @param in_container [NfsStore::Manage::Container]
      # @param from_path [String]
      # @param to_path [String]
      # @return [Integer] Number of files moved
      def self.move_folder(in_container, from_path, to_path)
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
      def move_to_trash!(remove_empty_dir: true)
        curr_path, = file_path_and_role_name
        unless curr_path
          raise FsException::Action, "Move to trash not allowed. File not accessible with current roles: #{curr_path}"
        end

        dt = DateTime.now.to_i
        new_file_name = "#{file_name}--#{dt}"
        move_to trash_path, new_file_name

        return unless curr_path && is_a?(ArchivedFile) && remove_empty_dir

        NfsStore::Archive::Mounter.remove_empty_archive_dir(curr_path)
      end

      # Move the file to its final location
      # @param from_path [String] the temporary path to move the file from
      # @return [Boolean] true if the file was moved successfully
      def move_from(from_path)
        res = false
        current_user_role_names.each do |role_name|
          # Cycle until we find a role that makes this directory writeable
          next unless Filesystem.test_dir role_name, container, :write

          # If a path is set, ensure we can make a directory for it if one doesn't exist
          unless path.blank? || Filesystem.test_dir(role_name, container, :mkdir,
                                                    extra_path: container_path(no_filename: true), ok_if_exists: true)
            next
          end

          cleanpath = Filesystem.clean_path(path)
          if cleanpath
            is_trash_path = self.class.trash_path?(cleanpath)

            if !is_trash_path && (cleanpath.start_with?('.') || cleanpath.start_with?('/'))
              raise FsException::Action, "Path to move to is bad: #{cleanpath}"
            end
          end

          to_path = if is_trash_path
                      cleanpath
                    else
                      container_path(no_filename: true)
                    end

          res = Filesystem.move_file_to_final_location role_name, from_path, container, to_path, file_name
          break if res
        end

        unless res
          raise FsException::NoAccess, 'User does not have permission to store file with any of the current groups'
        end

        true
      end

      #
      # Replace the current file content with a new file. The actual file content is replaced
      # so we generate a new digest, file size, etc
      #
      # @param [String] tmp_file_path the path to the temporary file
      # @return [Boolean] success
      #
      def replace_file!(tmp_file_path)
        # Retain the current file name and path
        orig_path = path
        orig_file_name = file_name

        blanked_path = path || ''
        if respond_to? :archive_file
          orig_archive_file = archive_file
          orig_file_path = File.join(blanked_path, orig_archive_file, orig_file_name)
        else
          orig_file_path = File.join(blanked_path, orig_file_name)
        end
        file_path, role_name = file_path_and_role_name
        new_trash_path = trash_path

        unless file_path
          raise FsException::Action, "Replacing file not allowed. File not accessible with current roles: #{file_path}"
        end

        orig_fs_path = Filesystem.nfs_store_path(role_name, container, path, file_name, archive_file: orig_archive_file)
        self.current_role_name = role_name

        transaction do
          # Move the current file to trash. Prevent removal of an empty directory
          # since the replacement will go back into it
          move_to_trash! remove_empty_dir: false

          unless self.class.trash_path?(path)
            raise FsException::Action, "Replacing file did not move original to trash: #{orig_file_path}"
          end

          trash_file_path = Filesystem.nfs_store_path(role_name, container, new_trash_path, file_name)
          unless File.exist?(trash_file_path)
            raise FsException::Action,
                  "Replacing file did not move the actual file to the trash filesystem location: #{trash_file_path}"
          end

          # Resetting file name and generating new hash, mime type, etc
          self.path = orig_path
          self.file_name = orig_file_name
          self.archive_file = orig_archive_file if respond_to? :archive_file
          self.valid_path_change = true

          rep_fs_path = Filesystem.nfs_store_path(role_name, container, path, file_name,
                                                  archive_file: orig_archive_file)
          unless rep_fs_path == orig_fs_path
            raise FsException::Action, "Replacement file targeting wrong location: #{rep_fs_path}"
          end

          # Move the temporary file to the original location
          move_from tmp_file_path

          self.file_hash = nil
          analyze_file!
          self.file_hash ||= ContainerFile.hash_for_file(rep_fs_path)

          # Remove the trash file
          Filesystem.remove_trash_file trash_file_path

          save!
        end

        true
      end

      #
      # Get the filesystem path and role name for the first role that allows
      # the container file to be accessed
      # @return [Array(String, String) | nil] returns an array [filesystem_path, role_name]
      def file_path_and_role_name
        current_user_role_names.each do |role_name|
          fs_path = file_path_for role_name: role_name
          return [fs_path, role_name] if File.exist?(fs_path)
        end
        nil
      end

      # Calculate a the MD5 hash for a file focusing on memory efficiency for large files by handling as chunks
      # NOTE: this should not be used directly against mounted archive files that are larger than one chunk,
      # since the overhead of continuous unzipping slows things enormously.
      # @param file_path [String] full path to the file
      # @return [String] MD5 hash
      def self.hash_for_file(file_path)
        md5_digest = Digest::MD5.new
        md5_digest.file(file_path)

        md5_digest.hexdigest
      end

      #
      # Is a value set in the file_metadata field?
      # Avoids deserializing the JSON
      # @return [true | false]
      def file_metadata_present?
        @file_metadata_present = !!file_metadata_before_type_cast.present? if @file_metadata_present.nil?
      end

      alias file_metadata_present file_metadata_present?

      def option_configs(force: false, raise_bad_configs: false)
        [option_type_config]
      end

      #
      # Option type config to allow a container file to act a little like a dynamic model.
      # Pulls the configurations from the {nfs_store: container_files: stored_file:, container_file:}
      # and uses the standard ExtraOptions configurations within the appropriate configuration.
      # @return [OptionConfigs::ContainerFilesOptions]
      def option_type_config
        return unless container

        eoc = container.extra_options_config
        return unless eoc

        config = eoc.nfs_store&.dig(:container_files, self.class.short_type)
        return unless config

        OptionConfigs::ContainerFilesOptions.new :default, config, self
      end

      #
      # Generate the URI that directly points to a file as a meaningful path of names rather than IDs.
      # For example:
      #    /nfs_store/downloads/in/activity_log__study_info_part/test-files/test/Project%20Viva%20Analysis%20Plan%20Presentation_Template-widescreen.pptx
      # This is used both in the file metadata show/edit block, and if the extra options config states:
      #   nfs_store:
      #     view_options:
      #       show_file_links_as: path
      # This is not used by default, to avoid large folders having performance issues, since this method has not been optimized.
      # Also, there is a known issue where a zip file has been uploaded inside a folder, such that the *archive_file* attribute
      # of an ArchivedFile is something like `holds-zip/zip-file.zip``. There is no sensible way for this to passed in path, so it will
      # fail on retrieval. To work around this, we check for #archive_file containing a forward slash, and return nil in this case,
      # which allows a regular file path to be generated by the front end.
      def direct_uri
        container_parent = container.parent_item
        return unless container_parent

        return if respond_to?(:archive_file) && archive_file&.include?('/')

        parent_id = container_parent.secondary_key || container_parent.id

        enc_path_parts = []
        enc_path_parts << archive_file if respond_to?(:archive_file) && archive_file.present?
        enc_path_parts << path if path.present?
        enc_path_parts << file_name
        enc_path = enc_path_parts.join('/')

        enc_path = URI::Parser.new.escape(enc_path)

        "/nfs_store/downloads/in/#{container_parent.resource_item_name}/#{parent_id}/#{enc_path}"
      end

      private

      def reset_flags
        self.valid_path_change = false
      end

      def prevent_path_change
        return unless persisted? && !valid_path_change && path_changed?

        errors.add :path, 'must not be changed'
      end
    end
  end
end
