module SecureView
  #
  # Provide previewing functionality to DownloadsController
  module Previewing
    private

    def secure_view_action(path)
      return unless path

      if secure_view_do_what == 'info'
        secure_view_setup_previewer path
        secure_view_previewer_info
      elsif secure_view_do_what == 'convert_to'
        secure_view_setup_previewer path
        secure_view_preview_page
      end
    end

    def secure_view_setup_previewer(path, view_as: nil)
      raise GeneralException, 'No path for setup_previewer' unless path

      view_as ||= secure_view_preview_as
      case view_as
      when 'png'
        @secure_view_previewer = SecureView::ImagePreviewer.new path: path.to_s
      when 'icon'
        @secure_view_previewer = SecureView::ImagePreviewer.new path: path.to_s, view_type: :icon
      when 'html'
        @secure_view_previewer = SecureView::HtmlPreviewer.new path: path.to_s
      when 'pdf'
        @secure_view_previewer = SecureView::PdfPreviewer.new path: path.to_s
      end
    end

    def secure_view_preview_page
      req_page = secure_view_pagenum_to_retrieve
      @secure_view_previewer.preview(req_page) do |res|
        data = res[:io].read
        res.delete :io

        send_data data, res
      end
    end

    def secure_view_pagenum_to_retrieve
      secure_view_params[:page]&.to_i || 1
    end

    def secure_view_previewer_info
      j = {
        page_count: @secure_view_previewer.page_count,
        preview_as: secure_view_preview_as,
        default_zoom: @secure_view_default_zoom,
        can_preview: @secure_view_previewer.previewable?
      }

      render json: j
    end

    def secure_view_do_what
      secure_view_params[:do]
    end

    def secure_view_preview_as
      secure_view_params[:preview_as]
    end

    def secure_view_params
      @secure_view_params ||= params[:secure_view] || {}
    end
  end
end
