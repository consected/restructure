module NfsStore
  module OverrideContainerFile

    extend ActiveSupport::Concern

    # We force the methods in here to override existing methods in Container
    included do

      def current_user=user
        master.current_user = user
      end

      def current_user
        master.current_user
      end

      def master_id=master_id
        @master_id = master_id
      end

      def master_id
        container.master_id
      end


    end

    class_methods do
      def resource_name
        "nfs_store_containers"
      end


      def permitted_params
        super - [:id, :file_hash, :file_name, :content_type, :file_size, :path, :file_updated_at, :nfs_store_container_id]
      end

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

  end
end
