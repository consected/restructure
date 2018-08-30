module NfsStore
  module OverrideClassificationController


    extend ActiveSupport::Concern

    included do
      helper Application::ApplicationHelper

      before_action :prevent_cache
      before_action :authenticate_user!
      protect_from_forgery with: :exception

      helper_method :object_instance


      def find_container
        if action_name.in? ['create', 'update']
          cid = secure_params[:container_id]
        else
          cid = params[:id]
          params[:id] = params[:download_id]
        end
        @container = Browse.open_container id: cid, user: current_user
        @stored_file = @container.stored_files.where(id: params[:download_id]).first
        @master = @container.master
        @master.current_user ||= current_user
        @container
      end

    end

    protected
      def object_instance
        @stored_file
      end

      # return the class for the current item
      # handles namespace if the item is like an ActivityLog:Something
      def primary_model
        NfsStore::Manage::StoredFile
      end

      def object_name
        'stored_file'
      end

      # notice the double underscore for namespaced models to indicate the delimiter
      # to remain consistent with the associations
      def full_object_name
        'nfs_store__manage__stored_file'
      end

      # the association name from master to these objects
      # for example player_contacts or activity_log__player_contacts_phones
      # notice the double underscore for namespaced models to indicate the delimiter
      def objects_name
        :nfs_store__manage__stored_files
      end

      def human_name
        'File'
      end


  end
end
