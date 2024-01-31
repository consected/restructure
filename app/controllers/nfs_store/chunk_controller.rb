# frozen_string_literal: true

module NfsStore
  #
  # Manage the upload of fixed length data chunks for large file uploads.
  #
  # Each upload from a client can consist of one or more files, each sent as one or more chunks.
  # The reason for splitting files into chunks is it allows easy progress feedback from the server,
  # and in the case of failures, allows large file uploads to be restarted.
  # Multiple files may be uploaded as a batch, since we may require a notification to users to be
  # triggered one time after all the files have been uploaded, rather than for each individual file.
  class ChunkController < FsBaseController
    layout nil

    include InNfsStoreContainer

    #
    # Get details about an existing upload. If it exists this means that
    # a previous upload has been started. The client may not have completed the
    # overall upload process, so this facilitates restarting.
    def show
      container = params[:id]
      file_hash = params[:file_hash]
      file_name = params[:file_name]
      relative_path = params[:relative_path]

      unless Upload.filters_allow_upload? file_name, relative_path, @activity_log
        render json: {
          message: 'The filters do not allow upload of this file. Ensure the file is named correctly.',
          valid_filters: Upload.valid_filters(@activity_log)
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

    #
    # Create a new chunk on the server from a posted chunk,
    # which is accessed in the uploads param. This is attached to the
    # an existing upload if one is found, otherwise an upload is created
    # for other chunks to be attached to.
    def create
      chunk = params[:upload]
      find_container

      @upload = Upload.init content_type: chunk.content_type,
                            file_name: chunk.original_filename,
                            file_hash: params[:file_hash],
                            container_id: @container,
                            user: current_user,
                            relative_path: params[:relative_path],
                            upload_set: params[:upload_set]

      raise FsException::Upload, 'Upload could not be initialized' unless @upload

      @master = @upload.container.master
      @id = @upload.container.id
      @upload.consume_chunk upload: chunk, headers: request.headers, chunk_hash: params[:chunk_hash]

      respond_to do |format|
        if @upload&.errors&.empty? && @upload&.save
          format.html do
            render json: [@upload.to_jq_upload].to_json,
                   content_type: 'text/html',
                   layout: false
          end
          format.json do
            render json: { file: @upload.to_jq_upload }, status: :created
          end
        else
          errors = @upload ? @upload.errors : { upload: 'not initialized' }
          response.headers['X-Upload-Errors'] = errors.to_json
          format.html { render action: 'new' }
          format.json { render json: errors, status: :unprocessable_entity }
        end
      end
    end

    #
    # A put/patch request indicates to the server that a set of uploads have completed.
    # When notifications are required after a full set of multiple files have been uploaded
    # this allows the client to indicate that all the required files have been completed.
    def update
      return not_found unless @container

      act = params[:do]
      ui = params[:uploaded_ids]

      return not_authorized unless act == 'done'
      return bad_request if ui.blank?

      uis = ui.split(',').map(&:to_i)
      @container.upload_done uis
      render json: {
        result: 'done'
      }
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
