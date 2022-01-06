module SecureView
  #
  # Handle generation of PDFs to allow search of PDF and office documents
  class PDFPreviewer < BasePreviewer
    DefaultResolution = 150
    def self.file_type
      :pdf
    end

    def initialize(options = {})
      super
      office_docs_to :pdf unless pdf?
      # || viewable_image?
      # dicom_to_jpg if viewable_dicom?
    end

    # Return the page preview as a PDF format file
    def preview(_page)
      if pdf?
        output = File.open(path).read
        res = { io: output, filename: "#{path}.pdf" }
        yield res
      end
    end

    # Get the (possibly cached) page count for the PDF
    # @return [Integer | nil] the page count or nil if the info returns no page count information
    def page_count
      return 1 unless previewable? && !viewable_image?

      self.class.check_pdftoppm_exists!

      Rails.cache.fetch(cache_key(:page_count)) do
        IO.popen [SecureView::Config.pdfinfo_path, path] do |res|
          page_res = res.read.scan(/^Pages: \s*(\d+)/)
          return unless page_res.first&.first

          return page_res.first.first.to_i
        end
      end
    end

    #
    # Search the currently PDF (or the original file converted to a PDF) for the
    # exact search word or phrase
    # Yields the block to allow streaming of results
    # @param [String] search_string
    # @param [Integer] guide to the number of results to return. This is not exact.
    # @yield [Stdout] a streamed stdout from the pdfgrep program
    def search(search_string, max_count: 210, &block)
      return if search_string.blank?

      self.class.check_pdfgrep_exists!

      max_count = max_count.to_i.to_s
      cmd = [SecureView::Config.pdfgrep_path, '-i', '--max-count', max_count, '-n', '-F', search_string, path]
      IO.popen(cmd, &block)
    end
  end
end
