# frozen_string_literal: true

module NfsStore
  #
  # Handle file download / view requests for single and multiple files.
  # Additionally handle user "trigger" actions such as renaming and trashing files.
  # Multi file downloads generate a zip file that is downloaded to the client.

  class DownloadsController < FsBaseController
    #
    # Actions that are valid to be called from a post (create) action
    ValidActions = %i[trash download move_files rename_file trigger_file_action].freeze

    include InNfsStoreContainer
    include SecureView::Previewing

    before_action :setup_selected_items, only: %i[create trash]

    #
    # Request download of a single file for download or view
    # Specify either a download_id & retrieval_type or download_path
    def show
      @download_id = params[:download_id].to_i
      retrieval_type = params[:retrieval_type]
      for_action = :download
      for_action = :download_or_view if params.dig(:secure_view, :preview_as).present?
      download_path = params[:download_path]
      if download_path
        dl = Download.find_download_by_path(@container, download_path)
        retrieval_type = dl.retrieval_type
        @download_id = dl.id
      end

      raise FsException::NotFound, 'Requested file ID or path not found' unless @download_id

      retrieved_file = retrieve_file(@download_id, retrieval_type, for_action: for_action)
      raise FsException::NotFound, 'Requested file not found' unless retrieved_file

      @download.save!
      if use_secure_view && secure_view_do_what
        secure_view_action retrieved_file
        nil
      else
        send_file retrieved_file
      end
    end

    #
    # Handle the request for a user action to be triggered, such as rename or trash a file
    # or multiple files.
    def create
      do_action = @commit.split(':').first&.id_underscore
      do_action = ValidActions.select { |va| va == do_action&.to_sym }.first
      if do_action
        send do_action
      else
        not_found
      end
    end

    #
    # Download multiple files as a zip file
    def multi
      selected_items = secure_params[:selected_items]

      unless selected_items.is_a?(Array) && !selected_items.empty?
        raise FsException::Download, 'No items were selected for download'
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

    #
    # Search for string within a file, returning a live (streaming)
    # result set.
    # Future extension may allow search across multiple specified files.
    def search_doc
      @download_id = params[:download_id].to_i
      retrieval_type = params[:retrieval_type]
      search_string = params[:search_string]
      path = retrieve_file(@download_id, retrieval_type, force: true)

      retrieved_file = secure_view_setup_previewer(path, view_as: 'pdf')
      raise FsException::NotFound, 'Requested file not found' unless retrieved_file

      raise FsException::Action, 'No search string specified' if search_string.blank?

      response.headers['Content-Type'] = 'text/event-stream'
      response.headers['ETag'] = '0'
      response.headers['Last-Modified'] = Time.now.httpdate

      retrieved_file.search(search_string) do |stream|
        data = stream.gets
        while data
          response.stream.write data
          data = stream.gets
        end
      end
    ensure
      response.stream.close
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
      params.require(:nfs_store_download).permit(:container_id, :activity_log_id, :activity_log_type, :new_path,
                                                 :new_name, selected_items: [])
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

      @selected_items_info = selected_items.map do |s|
        h = JSON.parse(s)
        { id: h['id'].to_i, retrieval_type: h['retrieval_type'].to_sym }
      end
    end

    def setup_action(action_class)
      @action = action_class.new container_id: @container.id, multiple_items: true, activity_log: @activity_log
      @action.current_user = current_user
      @master = @container.master
      @id = @container.id
    end

    def handle_action_results(action_files)
      if action_files && !action_files.empty?
        @action.save!
        render json: action_files
      else
        redirect_to nfs_store_browse_path(@container)
      end
    end

    #
    # Retrieve a file to be downloaded or searched, or retrieve a portion of a document
    # for secure viewing, from the current container (@container) and master (@master)
    # Sets the @download, @master and @id (of the container) appropriately
    # @param [Integer] download_id
    # @param retrieval_type [Symbol] the type of object referencing the file
    # @param [Symbol] for_action :download (default) or :download_view
    # @param [true | nil] force: skip checking if a user has general user access control to download
    # @return [String] filesystem path to the file to be retrieved
    def retrieve_file(download_id, retrieval_type, for_action: :download, force: nil)
      raise FsException::Download, 'id invalid' unless download_id > 0
      raise FsException::Download, 'retrieval_type invalid' unless retrieval_type.present?

      retrieval_type = Download.validated_retrieval_type!(retrieval_type)
      @download = Download.new container: @container, activity_log: @activity_log
      @master = @container.master
      @id = @container.id
      @download.retrieve_file_from download_id, retrieval_type, for_action: for_action, force: force
    end
  end
end
