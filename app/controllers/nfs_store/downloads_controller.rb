module NfsStore
  class DownloadsController < FsBaseController

    include InNfsStoreContainer
    include SecureView::Previewing

    def show
      @download_id = params[:download_id].to_i
      retrieval_type = params[:retrieval_type]
      FsException::Download.new "id invalid" unless @download_id > 0
      FsException::Download.new "retrieval_type invalid" unless retrieval_type.present?
      # Avoid brakeman issue
      retrieval_type = NfsStore::Download::ValidRetrievalTypes.select{|r| r == retrieval_type.to_sym}.first

      FsException::Download.new "Invalid retreival type specified" unless Download.valid_retrieval_type? retrieval_type

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
        FsException::NotFound.new "Requested file not found"
      end
    end


    def create

      commit = params[:commit]
      selected_items = secure_params[:selected_items]

      unless selected_items.is_a?(Array) && selected_items.length > 0
        redirect_to nfs_store_browse_path(@container)
        return
      end

      selected_items_info = selected_items.map {|s| h = JSON.parse(s); {id: h['id'].to_i, retrieval_type: h['retrieval_type'].to_sym} }

      if commit == 'Download'

        @download = Download.new container_id: @container.id, multiple_items: true, activity_log: @activity_log
        @download.current_user = current_user
        @master = @container.master
        @id = @container.id
        retrieved_files = @download.retrieve_files_from selected_items_info
        if retrieved_files&.length > 0
          filename = "#{@download.container.name} - #{retrieved_files.length} #{'file'.pluralize(retrieved_files.length)}.zip"
          @download.save!
          send_file @download.zip_file_path, filename: filename
          # Do not attempt to cleanup the temp file by unlinking, since this will cause the out of band download to fail
        else
          redirect_to nfs_store_browse_path(@container)
        end

      elsif commit == 'Trash'

        @trash = Trash.new container_id: @container.id, multiple_items: true, activity_log: @activity_log
        @trash.current_user = current_user
        @master = @container.master
        @id = @container.id
        trashed_files = @trash.trash_all selected_items_info

        if trashed_files&.length > 0
          filename = "#{@trash.container.name} - #{trashed_files.length} #{'file'.pluralize(trashed_files.length)}.zip"
          @trash.save!

          render json: trashed_files
        else
          redirect_to nfs_store_browse_path(@container)
        end

      elsif commit == 'Move Files'
        new_path = secure_params[:new_path]

        @move = MoveAndRename.new container_id: @container.id, multiple_items: true, activity_log: @activity_log
        @move.current_user = current_user
        @master = @container.master
        @id = @container.id
        moved_files = @move.move_files selected_items_info, new_path

        if moved_files&.length > 0
          filename = "#{@move.container.name} - #{moved_files.length} #{'file'.pluralize(moved_files.length)}.zip"
          @move.save!

          render json: moved_files
        else
          redirect_to nfs_store_browse_path(@container)
        end

      elsif commit == 'Rename File'
        new_path = secure_params[:new_path]

        @move = MoveAndRename.new container_id: @container.id, multiple_items: true, activity_log: @activity_log
        @move.current_user = current_user
        @master = @container.master
        @id = @container.id
        moved_files = @move.move_files selected_items_info, new_path

        if moved_files&.length > 0
          filename = "#{@move.container.name} - #{moved_files.length} #{'file'.pluralize(moved_files.length)}.zip"
          @move.save!

          render json: moved_files
        else
          redirect_to nfs_store_browse_path(@container)
        end

      elsif commit == 'Rename Folder'
        new_path = secure_params[:new_path]

        @move = MoveAndRename.new container_id: @container.id, multiple_items: true, activity_log: @activity_log
        @move.current_user = current_user
        @master = @container.master
        @id = @container.id
        moved_files = @move.move_files selected_items_info, new_path

        if moved_files&.length > 0
          filename = "#{@move.container.name} - #{moved_files.length} #{'file'.pluralize(moved_files.length)}.zip"
          @move.save!

          render json: moved_files
        else
          redirect_to nfs_store_browse_path(@container)
        end

      else
        return not_found
      end
    end


    def multi

      selected_items = secure_params[:selected_items]

      unless selected_items.is_a?(Array) && selected_items.length > 0
        raise FsException::Download.new "No items were selected for download"
        return
      end

      selected_items_info = selected_items.map {|s|
        h = JSON.parse(s)
        {
          id: h['id'].to_i,
          container_id: h['container_id'].to_i,
          retrieval_type: h['retrieval_type'].to_sym,
          activity_log_type: h['activity_log_type'],
          activity_log_id: h['activity_log_id'].to_i
        }
      }

      container_ids = selected_items_info.map {|s| s[:container_id]}.uniq

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

      def secure_params
        params.require(:nfs_store_download).permit(:container_id, :activity_log_id, :activity_log_type, :new_path, {selected_items: []})
      end

      # Handle find container differently for multi container actions
      # If not multi, just continue with the standard InNfsStoreContainer before_action callback
      def find_container
        return if action_name == 'multi'
        super
      end

  end
end
