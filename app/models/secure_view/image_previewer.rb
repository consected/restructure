# frozen_string_literal: true

# Using Poppler Utils and Netpbm `(sudo apt-get | yum) install poppler-utils netpbm netpbm-progs`
# Also install libreoffice to allow headless conversions
#    libreoffice --headless --convert-to html '~/Downloads/mr_scans_full.xlsx'
#
module SecureView
  #
  # Handle generation of images to preview documents
  # Also generates icons
  class ImagePreviewer < BasePreviewer
    DefaultResolution = 150

    def self.file_type
      :pdf
    end

    #
    # Fit icon to number of pixels
    # @return [Array] x, y pixels
    def self.icon_scale
      [90, 90]
    end

    #
    # Immediately convert Office docs to PDF and DICOM images to JPEG
    # allowing the previewer to handle additional requirements from there
    # @param [Hash] options
    # @option options [Symbol] :view_type =>
    #                             :icon - indicates an icon size preview of page 1 is required
    #                              anything else for a standard screen sized image preview
    def initialize(options = {})
      super(**options)
      office_docs_to :pdf unless pdf? || viewable_image?
      dicom_to_jpg if viewable_dicom?
      self.view_type = options[:view_type]
    end

    # Return the page preview as a scaled viewable image format file
    def preview(page, &block)
      if view_type == :icon
        preview_image(page, scale: self.class.icon_scale, &block)
      else
        preview_image(page, &block)
      end
    end

    def preview_image(page, scale: nil, &block)
      if viewable_dicom?
        output = image_to_jpeg('jpeg', path, scale)
        res = { io: output, filename: "#{path}.jpg", disposition: 'inline' }
        block.call res
      elsif viewable_image?
        types = %w[jpeg png bmp gif tiff]
        types.each do |type|
          next unless image_is(type)

          output = image_to_jpeg(type, path, scale)
          res = { io: output, filename: "#{path}.jpg", disposition: 'inline' }
          block.call res
          break
        end

      else
        File.open(path) do |input|
          self.class.draw_pdf_page_from(input, page, scale: scale) do |resoutput|
            res = { io: resoutput, filename: "#{input.path}.jpg", content_type: :png }
            block.call res
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
          return nil unless page_res.first&.first

          return page_res.first.first.to_i
        end
      end
    end

    # Generate a command line and call the conversion
    def self.draw_pdf_page_from(file, page, resolution: nil, scale: nil, &block)
      check_pdftoppm_exists!

      send_args = [
        SecureView::Config.pdftoppm_path,
        '-singlefile'
      ]

      if resolution
        send_args += [
          '-r', resolution
        ]
      end

      if scale
        send_args += [
          '-scale-to-x', scale[0].to_s,
          '-scale-to-y', scale[1].to_s
        ]
      end

      send_args += [
        '-jpeg',
        '-f', page,
        '-l', page,
        file.path
      ]

      draw(*send_args, &block)
    end

    #
    # Convert an image to JPEG and cache it to avoid later conversions
    # Optionally scale the output JPEG to a specific number of pixels [x, y]
    # Return a StringIO buffer
    # @param [File | String] file - a File or String filepath for the source JPEG
    # @param [Array{Integer, Integer} | nil] scale - optional size to scale to [x, y]
    # @return [StringIO] resulting file data, allowing for IO read
    def image_to_jpeg(type, file, scale = nil, conv_attempts: 0)
      content = nil
      self.path = Rails.cache.fetch(cache_key('renderedpath')) do
        create_temp_dir
        path = file_cache_path 'jpg'

        content = self.class.image_to_jpeg(type, file, scale, output_type: :string)

        # Write the cache file
        File.write(path, content)
        path
      end

      # If we got a path from memcache (or we just generated it)
      if path && File.exist?(path)
        # If we just generated the file cache, content is set, if not, read it from the file path
        content ||= File.read(path)
        # The output is a StringIO
        content_io = StringIO.new content
        return content_io
      end

      raise GeneralException, "Failed to convert image file (#{type}) to jpeg - too many attempts" if conv_attempts > 2

      # Try again if the path was returned but the file does not exist
      Rails.cache.delete(cache_key('renderedpath'))
      image_to_jpeg type, file, scale, conv_attempts: conv_attempts + 1
    end

    #
    # Convert an image to a JPEG.
    # Optionally scale the output JPEG to a specific number of pixels [x, y]
    # Return a StringIO buffer
    # @param [File | String] file - a File or String filepath for the source JPEG
    # @param [Array{Integer, Integer} | nil] scale - optional size to scale to [x, y]
    # @return [StringIO] resulting file data, allowing for IO read
    def self.image_to_jpeg(type, file, scale = nil, output_type: :string_io)
      check_netpbm_exists!

      extra_options = []
      topnm_cmd = if type == 'jpeg'
                    'jpegtopnm'
                  elsif type == 'png'
                    extra_options = ['-mix']
                    'pngtopnm'
                  elsif type == 'bmp'
                    'bmptopnm'
                  elsif type == 'gif'
                    'giftopnm'
                  elsif type == 'tiff'
                    'tifftopnm'
                  end

      path = if file.is_a? String
               file
             else
               file.path
             end

      primary_cmd = ([topnm_cmd] + extra_options + [path])
      cmds = [primary_cmd]

      if scale
        cmds << [
          'pnmscale',
          '-xsize', scale[0].to_s,
          '-ysize', scale[1].to_s
        ]
      end

      cmds << ['pnmtojpeg']

      pipe_chain = Utilities::ProcessPipes.new(cmds)
      res = pipe_chain.run

      if output_type == :string
        res
      else
        StringIO.new res
      end
    rescue StandardError => e
      Rails.logger.warn "Failure in image previewer (#{pipe_chain}): #{e}"
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
