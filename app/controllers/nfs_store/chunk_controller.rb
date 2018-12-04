module NfsStore
  class ChunkController < FsBaseController
    layout nil

    include InNfsStoreContainer

    def show
      container = params[:id]
      file_hash = params[:file_hash]
      file_name = params[:file_name]
      relative_path = params[:relative_path]

      unless Upload.filters_allow_upload? file_name, relative_path, @activity_log
        render json: {
          message: "The filters do not allow upload of this file. Ensure the file is named correctly.",
          valid_filters: Upload.valid_filters(@activity_log),
        }, status: 403
        return
      end


      result = 'not found'
      begin
        @upload = Upload.find_upload container, file_hash, file_name, current_user, path: relative_path
      rescue FsException::Upload => e
        result = "cannot resume: #{e.inspect}"
      end

      if @upload
        @master = @upload.container.master
        @id = @upload.container.id

        render json: {
          result: 'found',
          completed: @upload.completed,
          chunk_count: @upload.chunk_count,
          file_size: @upload.file_size
        }
      else
        render json: {
          result: result
        }
      end
    end

    def create

      chunk = params[:upload]

      @upload = Upload.init content_type: chunk.content_type,
                            file_name: chunk.original_filename,
                            file_hash: params[:file_hash],
                            container_id: params[:container_id],
                            user: current_user,
                            relative_path: params[:relative_path]

      if @upload
        @master = @upload.container.master
        @id = @upload.container.id
        @upload.consume_chunk upload: chunk, headers: request.headers, chunk_hash: params[:chunk_hash]
      else
        raise FsException::Upload.new "Upload could not be initialized"
      end

      respond_to do |format|
        if @upload && @upload.save
          format.html {

            render :json => [@upload.to_jq_upload].to_json,
            :content_type => 'text/html',
            :layout => false
          }
          format.json {

            render json: {file: @upload.to_jq_upload}, status: :created
          }
        else
          errors = @upload ? @upload.errors : {upload: 'not initialized'}
          response.headers['X-Upload-Errors'] = errors.to_json
          format.html { render action: "new" }
          format.json { render json: errors,  status: :unprocessable_entity }
        end
      end
    end

    private


      def no_action_log
        action_name == 'show' && !@upload
      end

      def secure_params
        params
      end

  end
end
