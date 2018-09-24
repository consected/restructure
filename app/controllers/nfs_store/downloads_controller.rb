module NfsStore
  class DownloadsController < FsBaseController

    include InNfsStoreContainer

    def show
      @download_id = params[:download_id].to_i
      retrieval_type = params[:retrieval_type]
      FsException::Download.new "id invalid" unless @download_id > 0
      FsException::Download.new "retrieval_type invalid" unless retrieval_type.present?
      # Avoid brakeman issue
      retrieval_type = ValidRetrievalTypes.select{|r| r == retrieval_type.to_sym}.first

      FsException::Download.new "Invalid retreival type specified" unless Download.valid_retrieval_type? retrieval_type

      @download = Download.new container: @container
      @master = @container.master
      @id = @container.id
      retrieved_file = @download.retrieve_file_from @download_id, retrieval_type
      if retrieved_file
        @download.save!
        send_file retrieved_file
      else
        FsException::NotFound.new "Requested file not found"
      end
    end


    def create

      selected_items = secure_params[:selected_items]

      unless selected_items.is_a?(Array) && selected_items.length > 0
        redirect_to nfs_store_browse_path(@container)
        return
      end

      selected_items_info = selected_items.map {|s| h = JSON.parse(s); {id: h['id'].to_i, retrieval_type: h['retrieval_type'].to_sym} }

      @download = Download.new container: @container, multiple_items: true
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

    end

    private

      def secure_params
        params.require(:nfs_store_download).permit(:container_id, {selected_items: []})
      end



  end
end
