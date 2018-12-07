module NfsStore
  class Download < NfsStoreUserBase

    self.table_name = 'nfs_store_downloads'

    include HasCurrentUser

    belongs_to :user
    belongs_to :container, class_name: "NfsStore::Manage::Container", foreign_key: 'nfs_store_container_id'

    ValidRetrievalTypes = %i(stored_file archived_file)

    before_validation :store_retrieved_items

    attr_accessor :retrieval_type, :selected_items, :multiple_items, :zip_file_path, :all_retrieved_items, :file_metadata, :activity_log
    alias_attribute :container_id, :nfs_store_container_id
    alias_attribute :container_ids, :nfs_store_container_ids

    # Check if requested retrieval type is one of a valid set
    # @param retrieval_type [Symbol] retrieval type requested
    # @return [True, False]
    def self.valid_retrieval_type? retrieval_type
      retrieval_type.in? ValidRetrievalTypes
    end

    # Initialize download with NfsStore::Download.new ...
    # @param options [Hash{container=>(NfsStore::Manage::Container), multiple_items=>(True,False)}]
    #   container - the container holding the files - must be set
    #     during initialization or immediately after
    #   multiple_items (optional) specifies if this is a download of one or more files in a zip
    #   user is no longer specified, since this is set from the container during retrieval
    def initialize options={}
      super
    end

    # Override the standard current_user setting to allow multiple containers / masters to be handled
    def current_user=user
      if container_ids
        @current_user = user
      else
        master ||= self.container.master
        master.current_user = user
      end
    end

    def current_user
      if container_ids
        @current_user
      else
        master ||= self.container.master
        master.current_user
      end
    end

    # Memoize filtered container files, returning a hash for stored and archived files
    # @param item_for_filter [NfsStore::Manage::Container | ActivityLog]
    # @return [Hash {stored_files: ActiveRecord::Relation, archived_files: ActiveRecord::Relation}]
    def filtered_files_as_scopes item_for_filter
      rnid = "#{item_for_filter.class.to_s.ns_underscore}--#{item_for_filter.id}"
      @filtered_files_as_scopes ||= {}
      @filtered_files_as_scopes[rnid] ||= NfsStore::Filter::Filter.evaluate_container_files_as_scopes item_for_filter
    end

    # Retrieve a file of a specific type (stored file or archived file) from a container
    # @param id [Integer] the ID of the object
    # @param retrieval_type [Symbol] the type of object referencing the file
    # @param container [NfsStore::Manage::Container | nil] optionally provide a container to support multi container downloads
    # @return [String] filesystem path to the file to be retrieved
    def retrieve_file_from id, retrieval_type, container: nil, activity_log: nil

      container ||= self.container
      activity_log ||= self.activity_log

      raise FsException::NoAccess.new "user does not have access to this container" unless container.allows_current_user_access_to? :access

      unless activity_log
        res = ModelReference.find_where_referenced_from(container).first
        raise FsException::NoAccess.new "Attempting to browse a container that is referenced by activity logs, without specifying which one" if res
      end

      item_for_filter = activity_log || container

      filtered_files = filtered_files_as_scopes item_for_filter

      if retrieval_type == :stored_file
        retrieved_file = filtered_files[:stored_files].select {|f| f.id == id }.first
      elsif retrieval_type == :archived_file
        retrieved_file = filtered_files[:archived_files].select {|f| f.id == id }.first
      else
        raise FsException::Download.new "Invalid retrieval type requested for download: #{retrieval_type}"
      end

      raise FsException::Download.new "The requested file either does not exist or you do not have access to it" unless retrieved_file

      # Save the list of gids this user has
      self.user_groups = retrieved_file.current_user_group_ids
      self.container = retrieved_file.container
      self.user = self.current_user

      # The details we save is dependent on whether we are downloading a single file, or a set of multiple items
      if multiple_items
        self.all_retrieved_items ||= []

        self.all_retrieved_items << {

          retrieval_type: retrieval_type,
          container_id: container.id,
          id: id,
          file_name: retrieved_file.file_name,
          parent_name: retrieved_file.container.parent_sub_dir || "master-id-#{retrieved_file.container.master_id}",
          container_name: retrieved_file.container.directory_name,
          container_path: retrieved_file.container_path(no_filename: true),
          retrieval_path: retrieved_file.retrieval_path,
          file_metadata: retrieved_file.file_metadata
        }
      else
        self.retrieval_path = retrieved_file.retrieval_path
        self.retrieval_type = retrieval_type
        self.file_metadata = retrieved_file.file_metadata
      end

      FsException::NotFound.new "file not found with available group access" unless self.retrieval_path

      self.retrieval_path
    end


    # Handle the retrieval of muliple requested files, returning an array of results
    # Each result is a hash referencing the requested id/retrieval_type
    # @param selected_items [Hash{id=>Integer, retrieval_type=>Symbol}] a hash of items to retrieve, with each ID qualified by a retrieval type
    # @return [Array(Hash{retrieval_type=>Symbol, id=>Integer, file_name=>String, container_path=>String, retrieval_path=>String})]
    #  id and retrieval_type match the requested item
    #  file_name is the simple file name
    #  container_path represents the local path within the container
    #  retrieval_path is the filesystem path from which the file can be retrieved
    def retrieve_files_from selected_items

      # Retrieve each file's details. The container_id will be passed if this is a
      # multi container download, otherwise it will be ignored
      selected_items.each do |s|
        container = self.container || Browse.open_container(id: s[:container_id], user: self.current_user)
        activity_log = self.activity_log || ActivityLog.open_activity_log(s[:activity_log_type], s[:activity_log_id], self.current_user)
        retrieve_file_from(s[:id], s[:retrieval_type], container: container, activity_log: activity_log)
      end
      self.zip_file_path = NfsStore::Archive::ZipFileGenerator.zip_retrieved_items self.all_retrieved_items

      self.all_retrieved_items
    end


    private

      # During save of the download record, copy all_retrieved_items to the actual retrieved_items attribute
      # We do this to handle the difference between JSON in Postgres and SQLite
      def store_retrieved_items
        if self.class.columns_hash["retrieved_items"].type == :string
          self.retrieved_items = self.all_retrieved_items.to_json
        else
          self.retrieved_items = self.all_retrieved_items
        end
      end


  end
end
