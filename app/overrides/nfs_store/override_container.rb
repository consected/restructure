module NfsStore
  module OverrideContainer

    extend ActiveSupport::Concern

    # We force the methods in here to override existing methods in Container
    included do

      def current_user=user
        master.current_user = user
      end

      def current_user
        master.current_user
      end

      # Container-specific sub directory to place container directory into
      # @return [nil | String] set to a sub path string such as 'holder123' or 'parentdir/holder123'
      def parent_sub_dir
        "master-#{self.master_id}"
      end

    end

    class_methods do
      def resource_name
        'nfs_store_container'
      end

      def human_name
        'File Container'
      end
    end

    def data
      name
    end

    def human_name
      name
    end

    def resource_name
      self.class.resource_name
    end

    def allows_current_user_access_to? perform, with_options=nil
      super
    end

  end
end
