module SecureView
  class Previewer

    DefaultResolution = 150
    DocumentExtensions = %w(doc docx odt html)
    SpreadsheetExtensions = %w(xls xlsx ods csv)
    PresentationExtensions = %w(ppt pptx odp odg)
    OfficeDocTypesTo = %w(html pdf)

    class << self
      attr_accessor :pdftoppm_exists, :libreoffice_exists
    end

    attr_accessor :path, :temp_dir, :orig_path

    def initialize path:
      self.path = path
      self.orig_path = self.path
    end

    # Get the configured resolution for file type, or default
    # @return [Integer] resolution in DPI
    def self.resolution
      SecureView::Config.resolution[file_type] || DefaultResolution
    end

    def cleanup
      if self.temp_dir
        FileUtils.remove_entry_secure self.temp_dir
      end
    end

    def previewable?
      !!(document? || spreadsheet? || presentation? || pdf?)
    end

    def self.open_tempfile
      tempfile = Tempfile.open("SecureView-", SecureView::Config.tempdir) do |f|
        yield f
      end
    end

    def self.change_extension path, to_ext
      (path.split('.')[0..-2] + [to_ext]).join('.')
    end


    # Check if pdftoppm exists at the configured path
    # Memoize the result in a class instance variable
    def self.pdftoppm_exists?
      return pdftoppm_exists unless pdftoppm_exists.nil?
      pdftoppm_exists = !!system(SecureView::Config.pdftoppm_path, "-v", out: File::NULL, err: File::NULL)
    end

    def self.libreoffice_exists?
      return libreoffice_exists unless libreoffice_exists.nil?
      libreoffice_exists = !!system(SecureView::Config.libreoffice_path, "--version", out: File::NULL, err: File::NULL)
    end

    # Raise an error unless pdftoppm exists. Assume that other pdf utils are correctly accessible based on this
    def self.check_pdftoppm_exists!
      raise ConfigException.new "pdftoppm does not exist at path specified: #{SecureView::Config.pdftoppm_path}" unless pdftoppm_exists?
    end

    # Raise an error unless libreoffice exists.
    def self.check_libreoffice_exists!
      raise ConfigException.new "libreoffice does not exist at path specified: #{SecureView::Config.libreoffice_path}" unless libreoffice_exists?
    end

    private


      def cache_key type
        "SecureView-doc-#{self.orig_path}-#{self.class.file_type}-#{type}"
      end

      def create_temp_dir
        self.temp_dir = Dir.mktmpdir 'secure-view-lo-output'
      end

      def mime_type
        @mime_type ||= MIME::Types.type_for(self.path)&.first
      end

      def pdf?
        mime_type == MIME::Type.new('application/pdf')
      end

      def html?
        mime_type == MIME::Type.new('text/html')
      end

      def spreadsheet?
        is_file_with_extensions SpreadsheetExtensions
      end

      def document?
        is_file_with_extensions DocumentExtensions
      end

      def presentation?
        is_file_with_extensions PresentationExtensions
      end

      def is_file_with_extensions extensions
        extensions.each do |ext|
          mt = MIME::Types.type_for("doc.#{ext}")
          return true if mime_type == mt
        end
        return
      end

      def office_docs_to type, conv_attempts: 0
        self.class.check_libreoffice_exists!

        type = type.to_s
        raise GeneralException.new "Invalid type to convert office doc type to: #{type}" unless type.in? OfficeDocTypesTo

        if previewable? || (pdf? && type != 'pdf')
          Rails.logger.info "Converting file #{self.orig_path}"

          self.path = Rails.cache.fetch(cache_key('renderedpath')) do

            create_temp_dir

            res = system(SecureView::Config.libreoffice_path, "--headless", "--convert-to", type, "--outdir", self.temp_dir, self.orig_path, out: File::NULL, err: File::NULL)
            raise GeneralException.new "Failed to convert file to #{type}" unless res

            conv_attempts += 1
            self.path = File.join(self.temp_dir, self.class.change_extension(File.basename(self.orig_path), type))
          end

          unless self.path && File.exist?(self.path)
            raise GeneralException.new "Failed to convert file to #{type} - too many attempts" if conv_attempts > 2
            # Try again if the path was returned but the file does not exist
            Rails.cache.delete(cache_key('renderedpath'))
            office_docs_to type, conv_attempts: conv_attempts + 1
          end

        else
          Rails.logger.info "Did not convert the file. Not a previewable type"
        end

      end


  end
end
