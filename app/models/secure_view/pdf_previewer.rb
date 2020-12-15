# Using Poppler Utils `sudo apt-get install poppler-utils`
# Also install libreoffice
#    libreoffice --headless --convert-to html '~/Downloads/mr_scans_full.xlsx'

module SecureView
  class PDFPreviewer < Previewer
    DefaultResolution = 150
    attr_accessor :view_type

    def self.file_type
      :pdf
    end

    #
    # Fit icon to number of pixels
    # @return [Array] x, y pixels
    def self.icon_scale
      [90, 90]
    end

    def initialize(options = {})
      super
      office_docs_to :pdf unless pdf? || viewable_image?
      dicom_to_jpg if viewable_dicom?
      self.view_type = options[:view_type]
    end

    # Return the page preview as a PNG format file
    def preview(page)
      if view_type == :icon
        if viewable_image? || viewable_dicom?
          File.open(path) do |output|
            res = { io: output, filename: output.path.to_s, disposition: 'inline' }
            yield res
          end
        else
          File.open(path) do |input|
            self.class.draw_icon_from(input, page) do |output|
              res = { io: output, filename: "#{input.path}.png", content_type: :png }
              yield res
            end
          end
        end
      elsif viewable_image? || viewable_dicom?
        File.open(path) do |output|
          res = { io: output, filename: output.path.to_s, disposition: 'inline' }
          yield res
        end
      else
        File.open(path) do |input|
          self.class.draw_page_from(input, page) do |output|
            res = { io: output, filename: "#{input.path}.png", content_type: :png }
            yield res
          end
        end
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

    # Generate a command line and call the conversion
    def self.draw_page_from(file, page, force_resolution = nil, &block)
      force_resolution ||= resolution
      check_pdftoppm_exists!
      draw SecureView::Config.pdftoppm_path,
           '-singlefile',
           '-r', force_resolution,
           '-jpeg',
           '-f', page,
           '-l', page,
           file.path,
           &block
    end

    def self.draw_icon_from(file, page = 1, force_scale = nil, &block)
      force_scale ||= icon_scale
      check_pdftoppm_exists!
      draw SecureView::Config.pdftoppm_path,
           '-singlefile',
           '-scale-to-x', force_scale[0],
           '-scale-to-y', force_scale[1],
           '-jpeg',
           '-f', page,
           '-l', page,
           file.path,
           &block
    end

    # Convert a page using pdftoppm and ActiveStorage instrumentation, based on the command line specified
    # Adapted from ActiveStorage Poppler previewer
    def self.draw(*argv)
      open_tempfile do |file|
        instrument :preview, key: file.path do
          capture(*argv, to: file)
        end
        yield file
      end
    end

    # Instrument the conversion using ActiveSupport
    def self.instrument(operation, payload = {}, &block)
      ActiveSupport::Notifications.instrument "#{operation}.active_storage", payload, &block
    end

    # Get the results from the conversion
    def self.capture(*argv, to:)
      call_args = argv.map(&:to_s)
      to.binmode
      IO.popen(call_args, err: File::NULL) { |out| IO.copy_stream(out, to) }
      to.rewind
    end
  end
end
