module Filestore
  class ClassificationController < UserBaseController # < NfsStoreController

    # helper Application::ApplicationHelper

    include NfsStore::InNfsStoreContainer
    # include ModelNaming
    # include ControllerUtils
    # include AppExceptionHandler
    # include UserActionLogging
    include MasterHandler


    before_action :prevent_cache
    before_action :authenticate_user!
    protect_from_forgery with: :exception

    helper_method :object_instance, :edit_form_hash, :edit_form_id, :inline_cancel_button


    def edit

      render partial: 'filestore/classification/edit'
    end

    def create
      render text: ''
    end

    protected

      def find_container

        if action_name.in? ['create', 'update']
          cid = params[:container_id]
        else
          cid = params[:id]
          params[:id] = params[:download_id]
        end
        @container = NfsStore::Browse.open_container id: cid, user: current_user
        if params[:retrieval_type] == 'stored_file'
          @download = @container.stored_files.where(id: params[:download_id]).first
        elsif params[:retrieval_type] == 'archived_file'
          @download = @container.archived_files.where(id: params[:download_id]).first
        end
        @master = @container.master
        @master.current_user ||= current_user
        @container
      end

      def hyphenated_name
        'filestore-classification'
      end

      def edit_form_id
        "#{hyphenated_name}-edit-form--#{@container.id}"
      end

      def edit_form_hash extras={}
        res = extras.dup

        res[:remote] = true
        res[:html] ||= {}
        res[:html].merge!("data-result-target" => "#container-entry-#{@container.id}-#{ @download.id }-#{ @download.class.retrieval_type} .bem-classification-attrs", "data-template" => "#{hyphenated_name}-result-template")
        res[:url] = master_filestore_classification_path(object_instance.master_id, object_instance.id, container_id: @container.id)

        res
      end

      def inline_cancel_button class_extras="pull-right"
        "<a class=\"show-entity show-#{hyphenated_name} #{class_extras} glyphicon glyphicon-remove-sign dropup\" title=\"cancel\" href=\"##{hyphenated_name}-edit-form--#{@container.id}\" data-toggle=\"collapse\"></a>".html_safe
      end

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


    private

      def secure_params
        params.require(:manage_stored_file).permit(*permitted_params)
      end



  end
end
