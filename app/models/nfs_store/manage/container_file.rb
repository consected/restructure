module NfsStore
  module Manage

    # Abract class from which file metata that is stored in the database are subclassed
    class ContainerFile < UserBase

      after_create :process_new_file



      self.abstract_class = true
      def self.no_master_association
        true
      end

      # include HandlesUserBase
      include UserHandler
      include HasCurrentUser

      def self.resource_name
        "nfs_store_containers"
      end


      def self.permitted_params
        super - [:id, :file_hash, :file_name, :content_type, :file_size, :path, :file_updated_at, :nfs_store_container_id, :archive_file]
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


      def as_json extras={}
        extras[:methods] ||= []
        extras[:methods] << :master_id
        super
      end

  
      # After creating a new container_file record we should process it.
      # This will kick off the processing loop
      def process_new_file

        ph = NfsStore::Process::ProcessHandler.new(self)
        ph.run_all

      end

    end
  end
end
