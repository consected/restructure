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

    end

    class_methods do
      def resource_name
        'nfs_store_container'
      end

    end

    def data
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
