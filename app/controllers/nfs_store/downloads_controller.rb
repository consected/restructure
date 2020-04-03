# frozen_string_literal: true

module NfsStore
  class DownloadsController < FsBaseController
    #
    # Actions that are valid to be called from a post (create) action
    ValidActions = %i[trash download move_files rename_file trigger_file_action].freeze

    include InNfsStoreContainer
    include SecureView::Previewing

    before_action :setup_selected_items, only: %i[create trash]

    def show
      @download_id = params[:download_id].to_i
      retrieval_type = params[:retrieval_type]
      FsException::Download.new 'id invalid' unless @download_id > 0
      FsException::Download.new 'retrieval_type invalid' unless retrieval_type.present?
      # Avoid brakeman issue
      retrieval_type = NfsStore::Download::ValidRetrievalTypes.select { |r| r == retrieval_type.to_sym }.first

      FsException::Download.new 'Invalid retreival type specified' unless Download.valid_retrieval_type? retrieval_type

      @download = Download.new container: @container, activity_log: @activity_log
      @master = @container.master
      @id = @container.id
      retrieved_file = @download.retrieve_file_from @download_id, retrieval_type, for_action: :download
      if retrieved_file
        @download.save!
        if use_secure_view && secure_view_do_what
          secure_view_action retrieved_file
          return
        else
          send_file retrieved_file
        end
      else
        FsException::NotFound.new 'Requested file not found'
      end
    end

    def create
      do_action = @commit.split(':').first&.id_underscore
      do_action = ValidActions.select { |va| va == do_action&.to_sym }.first
      if do_action
        send do_action
      else
        not_found
      end
    end

    def multi
      selected_items = secure_params[:selected_items]

      unless selected_items.is_a?(Array) && !selected_items.empty?
        raise FsException::Download, 'No items were selected for download'
        return
      end

      selected_items_info = selected_items.map do |s|
        h = JSON.parse(s)
        {
          id: h['id'].to_i,
          container_id: h['container_id'].to_i,
          retrieval_type: h['retrieval_type'].to_sym,
          activity_log_type: h['activity_log_type'],
          activity_log_id: h['activity_log_id'].to_i
        }
      end

      container_ids = selected_items_info.map { |s| s[:container_id] }.uniq

      @download = Download.new multiple_items: true, container_ids: container_ids
      @download.current_user = current_user

      retrieved_files = @download.retrieve_files_from selected_items_info
      if retrieved_files&.length > 0
        filename = "#{@download.container.name} - #{retrieved_files.length} #{'file'.pluralize(retrieved_files.length)}.zip"
        @download.save!
        send_file @download.zip_file_path, filename: filename
        # Do not attempt to cleanup the temp file by unlinking, since this will cause the out of band download to fail
      else
        redirect_to nfs_store_browse_path(@container)
      end
    end

    private

    def trash
      setup_action Trash
      trashed_files = @action.trash_all @selected_items_info
      handle_action_results trashed_files
    end

    def move_files
      new_path = secure_params[:new_path]
      setup_action MoveAndRename
      moved_files = @action.move_files @selected_items_info, new_path
      handle_action_results moved_files
    end

    def rename_file
      new_name = secure_params[:new_name]
      setup_action MoveAndRename
      moved_files = @action.rename_file @selected_items_info, new_name
      handle_action_results moved_files
    end

    def trigger_file_action
      action_id = @commit.sub('Trigger File Action: ', '')
      setup_action UserFileAction
      actioned_files = @action.perform_action @selected_items_info, action_id
      handle_action_results actioned_files
    end

    def download
      setup_action Download
      @download = @action
      retrieved_files = @download.retrieve_files_from @selected_items_info
      if retrieved_files&.present?
        filename = "#{@download.container.name} - #{retrieved_files.length} #{'file'.pluralize(retrieved_files.length)}.zip"
        @download.save!
        send_file @download.zip_file_path, filename: filename
        # Do not attempt to cleanup the temp file by unlinking, since this will cause the out of band download to fail
      else
        redirect_to nfs_store_browse_path(@container)
      end
    end

    def secure_params
      params.require(:nfs_store_download).permit(:container_id, :activity_log_id, :activity_log_type, :new_path, :new_name, selected_items: [])
    end

    # Handle find container differently for multi container actions
    # If not multi, just continue with the standard InNfsStoreContainer before_action callback
    def find_container
      return if action_name == 'multi'

      super
    end

    def setup_selected_items
      @commit = params[:commit]
      selected_items = secure_params[:selected_items]

      unless selected_items.is_a?(Array) && !selected_items.empty?
        redirect_to nfs_store_browse_path(@container)
        return
      end

      @selected_items_info = selected_items.map { |s| h = JSON.parse(s); { id: h['id'].to_i, retrieval_type: h['retrieval_type'].to_sym } }
    end

    def setup_action(action_class)
      @action = action_class.new container_id: @container.id, multiple_items: true, activity_log: @activity_log
      @action.current_user = current_user
      @master = @container.master
      @id = @container.id
    end

    def handle_action_results(action_files)
      if action_files && !action_files.empty?
        filename = "#{@container.name} - #{action_files.length} #{'file'.pluralize(action_files.length)}.zip"
        @action.save!

        render json: action_files
      else
        redirect_to nfs_store_browse_path(@container)
      end
    end
  end
end
