# frozen_string_literal: true

module SecureView
  class BasePreviewer
    DefaultResolution = 150
    DocumentExtensions = %w[doc docx odt html rtf html md txt].freeze
    SpreadsheetExtensions = %w[xls xlsx ods csv].freeze
    PresentationExtensions = %w[ppt pptx odp odg].freeze
    OfficeDocTypesTo = %w[html pdf].freeze

    class << self
      attr_accessor :pdftoppm_exists, :libreoffice_exists, :dcmj2pnm_exists, :pdfgrep_exists
    end

    attr_accessor :path, :temp_dir, :orig_path, :view_type

    def initialize(path:, view_type: nil)
      self.path = path
      self.orig_path = self.path
      self.view_type = view_type
    end

    # Get the configured resolution for file type, or default
    # @return [Integer] resolution in DPI
    def self.resolution
      SecureView::Config.resolution[file_type] || DefaultResolution
    end

    def cleanup
      FileUtils.remove_entry_secure temp_dir if temp_dir
    end

    def previewable?
      !!(document? || spreadsheet? || presentation? || pdf? || viewable_image? || text?)
    end

    def self.open_tempfile(&block)
      Tempfile.open('SecureView-', SecureView::Config.tempdir, &block)
    end

    def self.change_extension(path, to_ext)
      if path.include? '.'
        (path.split('.')[0..-2] + [to_ext]).join('.')
      else
        "#{path}.#{to_ext}"
      end
    end

    # Check if pdftoppm exists at the configured path
    # Memoize the result in a class instance variable
    def self.pdftoppm_exists?
      return @pdftoppm_exists unless @pdftoppm_exists.nil?

      @pdftoppm_exists = !!system(SecureView::Config.pdftoppm_path, '-v', out: File::NULL, err: File::NULL)
    end

    def self.libreoffice_exists?
      return @libreoffice_exists unless @libreoffice_exists.nil?

      @libreoffice_exists = !!system(SecureView::Config.libreoffice_path, '--version', out: File::NULL, err: File::NULL)
    end

    def self.dcmj2pnm_exists?
      return @dcmj2pnm_exists unless @dcmj2pnm_exists.nil?

      @dcmj2pnm_exists = !!system(SecureView::Config.dcmj2pnm_path, '--version', out: File::NULL, err: File::NULL)
    end

    def self.netpbm_exists?
      return @netpbm_exists unless @netpbm_exists.nil?

      @netpbm_exists = !!system(SecureView::Config.netpbm_path, '--version', out: File::NULL, err: File::NULL)
    end

    def self.pdfgrep_exists?
      return @pdfgrep_exists unless @pdfgrep_exists.nil?

      @pdfgrep_exists = !!system(SecureView::Config.pdfgrep_path, '--version', out: File::NULL, err: File::NULL)
    end

    # Raise an error unless pdftoppm exists. Assume that other pdf utils are correctly accessible based on this
    def self.check_pdftoppm_exists!
      return true if pdftoppm_exists?

      raise ConfigException, "pdftoppm does not exist at path specified: #{SecureView::Config.pdftoppm_path}"
    end

    # Raise an error unless netpm exists. Assume other PBM utils are correctly accessible based on this
    def self.check_netpbm_exists!
      return true if netpbm_exists?

      raise ConfigException, "netpbm does not exist at path specified: : #{SecureView::Config.netpbm_path}"
    end

    # Raise an error unless libreoffice exists.
    def self.check_libreoffice_exists!
      return true if libreoffice_exists?

      raise ConfigException, "libreoffice does not exist at path specified: #{SecureView::Config.libreoffice_path}"
    end

    def self.check_pdfgrep_exists!
      return true if pdfgrep_exists?

      raise ConfigException, "pdfgrep does not exist at path specified: #{SecureView::Config.pdfgrep_path}"
    end

    def file_cache_path(type)
      File.join(temp_dir, self.class.change_extension(File.basename(orig_path), type))
    end

    private

    def cache_key(type)
      "SecureView-doc-#{orig_path}-#{self.class.file_type}-#{type}-#{view_type}"
    end

    def create_temp_dir
      self.temp_dir = Dir.mktmpdir 'secure-view-lo-output'
    end

    def mime_type
      @mime_type ||= NfsStore::Utils::MimeType.full_mime_type(orig_path)
    end

    def viewable_image?
      mime_type == MIME::Type.new('image/png') ||
        mime_type == MIME::Type.new('image/jpeg') ||
        mime_type == MIME::Type.new('image/gif') ||
        mime_type == MIME::Type.new('image/bmp') ||
        mime_type == MIME::Type.new('image/tiff') ||
        viewable_dicom?
    end

    #
    # Does the image have this MIME type? Provide one of:
    # png, jpeg, gif, bmp
    # @param [String] type - simple type name
    # @return [Boolean] result
    def image_is(type)
      mime_type == MIME::Type.new("image/#{type}")
    end

    def dicom?
      mime_type == MIME::Type.new('application/dicom')
    end

    # Is it a dicom image, and can we handle dicom image conversions?
    def viewable_dicom?
      dicom? && self.class.dcmj2pnm_exists?
    end

    def viewable_tiff?
      tiff? && self.class.netpbm_exists?
    end

    def pdf?
      mime_type == MIME::Type.new('application/pdf')
    end

    def tiff?
      mime_type == MIME::Type.new('image/tiff')
    end

    def html?
      mime_type == MIME::Type.new('text/html')
    end

    def text?
      mime_type == MIME::Type.new('text/plain')
    end

    def spreadsheet?
      file_with_extensions? SpreadsheetExtensions
    end

    def document?
      file_with_extensions? DocumentExtensions
    end

    def presentation?
      file_with_extensions? PresentationExtensions
    end

    def file_with_extensions?(extensions)
      extensions.each do |ext|
        mt = MIME::Types.type_for("doc.#{ext}")
        return true if mime_type == mt
      end
      nil
    end

    def office_docs_to(type, conv_attempts: 0)
      self.class.check_libreoffice_exists!

      type = type.to_s
      raise GeneralException, "Invalid type to convert office doc type to: #{type}" unless type.in? OfficeDocTypesTo

      if previewable? || (pdf? && type != 'pdf')
        Rails.logger.info "Converting file #{orig_path}"

        self.path = Rails.cache.fetch(cache_key('renderedpath')) do
          create_temp_dir

          # Avoid multiple threads and worker processes attempting to convert simultaneously
          # We should make this a backend tasks, with reloading in the UI, but for now...
          i = 0
          while Rails.cache.read(:libreoffice_parsing)
            # try anyway after 5 times
            Rails.logger.warn "Waiting for libreoffice_parsing -  #{i}"
            sleep 2
            i += 1
            next unless i >= 5

            kres = `ps aux | grep libreoffice`
            Rails.logger.warn "Libreoffice processes after 5 attempts:\n#{kres}"
            kres = `pkill oosplash`
            Rails.logger.warn "Killed oosplash: #{kres}"
            break
          end

          Rails.cache.write :libreoffice_parsing, 'lock', expires_in: 10.seconds

          res = system(SecureView::Config.libreoffice_path,
                       '--headless',
                       '--norestore',
                       '--convert-to', type,
                       '--outdir', temp_dir,
                       orig_path,
                       out: File::NULL, err: File::NULL)

          Rails.cache.delete :libreoffice_parsing
          unless res
            raise GeneralException,
                  "Failed to convert file to #{type} - error code #{res} - #{orig_path}"
          end

          conv_attempts += 1
          self.path = file_cache_path type
        end

        unless path && File.exist?(path)
          if conv_attempts > 2
            raise GeneralException,
                  "Failed to convert file to #{type} - too many attempts - #{orig_path}"
          end

          # Try again if the path was returned but the file does not exist
          Rails.cache.delete(cache_key('renderedpath'))
          office_docs_to type, conv_attempts: conv_attempts + 1
        end

      else
        Rails.logger.info 'Did not convert the file. Not a previewable type'
      end
    end

    #
    # Attempt to convert DICOM images to JPEG, with several retries
    # Sets @path with file path of output image if conversion is successful
    # @param [Integer] conv_attempts - number of conversion attempts made
    # @return [String | nil] file path of converted image or nil if conversion failed
    def dicom_to_jpg(conv_attempts: 0, force_scale: nil)
      unless self.class.dcmj2pnm_exists?
        Rails.logger.info 'dcmj2pnm does not exist. Not converting.'
        return
      end

      unless viewable_dicom?
        Rails.logger.info 'Did not convert the file. Not a previewable type'
        return
      end

      Rails.logger.info "Converting file #{orig_path}"

      self.path = Rails.cache.fetch(cache_key('renderedpath')) do
        create_temp_dir
        path = file_cache_path 'jpg'

        send_args = [
          SecureView::Config.dcmj2pnm_path,
          '--write-jpeg',
          '--histogram-window', '1'
        ]

        if force_scale
          send_args += [
            '--scale-x-size', force_scale[0],
            '--scale-y-size', force_scale[1]
          ]
        end

        send_args += [orig_path, path]

        system(*send_args, out: File::NULL, err: File::NULL)
        path
      end

      return path if path && File.exist?(path)

      raise GeneralException, 'Failed to convert dicom file to jpeg - too many attempts' if conv_attempts > 2

      # Try again if the path was returned but the file does not exist
      Rails.cache.delete(cache_key('renderedpath'))
      dicom_to_jpg conv_attempts: conv_attempts + 1
    end
  end
end
