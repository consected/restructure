module Filestore
  class ClassificationController < UserBaseController

    include NfsStore::InNfsStoreContainer
    include MasterHandler

    helper_method :object_instance, :edit_form_hash, :edit_form_id, :inline_cancel_button, :caption


    def edit
      prep_item_flags
      render partial: 'filestore/classification/edit', locals: {caption: @retrieval_type.humanize}
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
        @retrieval_type = params[:retrieval_type]
        if @retrieval_type == 'stored_file'
          @download = @container.stored_files.where(id: params[:download_id]).first
        elsif @retrieval_type == 'archived_file'
          @download = @container.archived_files.where(id: params[:download_id]).first
        else
          raise FphsException.new 'Incorrect retrieval_type set'
        end

        @master = @container.master
        @master.current_user ||= current_user
        @container
      end

      def hyphenated_name
        "filestore-classification-#{object_name.hyphenate}"
      end

      def edit_form_id
        "#{hyphenated_name}-edit-form--#{@container.id}"
      end

      def edit_form_hash extras={}
        res = extras.dup

        res[:remote] = true
        res[:html] ||= {}
        res[:html].merge!("data-result-target" => "#container-entry-#{@container.id}-#{ @download.id }-#{ @download.class.retrieval_type} .bem-classification-attrs", "data-template" => "#{hyphenated_name}-result-template")
        res[:url] = master_filestore_classification_path(object_instance.master_id, object_instance.id, container_id: @container.id, retrieval_type: @retrieval_type)

        res
      end

      def inline_cancel_button class_extras="pull-right"
        "<a class=\"show-entity show-#{hyphenated_name} #{class_extras} glyphicon glyphicon-remove-sign dropup\" title=\"cancel\" data-target=\"[data-subscription='#{hyphenated_name}-edit-form--#{@container.id}']\" data-toggle=\"clear-content\"></a>".html_safe
      end


      # return the class for the current item
      # handles namespace if the item is like an ActivityLog:Something
      def primary_model
        if params[:retrieval_type] == 'stored_file'
          NfsStore::Manage::StoredFile
        elsif params[:retrieval_type] == 'archived_file'
          NfsStore::Manage::ArchivedFile
        else
          raise FphsException.new "No retrieval_type set"
        end
      end

      def object_name
        if params[:retrieval_type] == 'stored_file'
          'stored_file'
        elsif params[:retrieval_type] == 'archived_file'
          'archived_file'
        else
          raise FphsException.new "No retrieval_type set"
        end
      end

      # notice the double underscore for namespaced models to indicate the delimiter
      # to remain consistent with the associations
      def full_object_name
        "nfs_store__manage__#{object_name}"
      end

      # the association name from master to these objects
      # for example player_contacts or activity_log__player_contacts_phones
      # notice the double underscore for namespaced models to indicate the delimiter
      def objects_name
        full_object_name.pluralize.to_sym
      end

      def human_name
        'File'
      end


    private

      def secure_params
        params.require("nfs_store_manage_#{object_name}".to_sym).permit(*permitted_params)
      end



  end
end
