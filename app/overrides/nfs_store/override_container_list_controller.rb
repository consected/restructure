module NfsStore
  module OverrideContainerListController

    extend ActiveSupport::Concern

    included do
      before_action :prevent_cache
      before_action :authenticate_user!
      protect_from_forgery with: :exception

      def find_container
        if action_name.in? ['create', 'update']
          cid = secure_params[:container_id]
        else
          cid = params[:id]
        end
        @container = Browse.open_container id: cid, user: current_user
        @master = @container.master
        @master.current_user ||= current_user
        @container
      end

    end

    protected


      # return the class for the current item
      # handles namespace if the item is like an ActivityLog:Something
      def primary_model
        NfsStore::Manage::Container
      end

      def object_name
        'container'
      end

      # notice the double underscore for namespaced models to indicate the delimiter
      # to remain consistent with the associations
      def full_object_name
        'nfs_store__manage__container'
      end

      # the association name from master to these objects
      # for example player_contacts or activity_log__player_contacts_phones
      # notice the double underscore for namespaced models to indicate the delimiter
      def objects_name
        :nfs_store__manage__containers
      end

      def human_name
        'Container'
      end
  end
end
