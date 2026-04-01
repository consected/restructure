# frozen_string_literal: true

require 'open3'

module FullTextSearch
  module TextExtractor
    PDF_EXTENSIONS = %w[pdf].freeze
    TEXT_EXTENSIONS = %w[txt csv md html rtf].freeze
    OFFICE_EXTENSIONS = %w[doc docx xls xlsx ppt pptx odt ods odp odg].freeze

    ALL_EXTENSIONS = (PDF_EXTENSIONS + TEXT_EXTENSIONS + OFFICE_EXTENSIONS).freeze

    module_function

    def extract_text(file_path)
      raise FphsException, "File does not exist: #{file_path}" unless File.exist?(file_path)

      ext = File.extname(file_path).delete('.').downcase

      if PDF_EXTENSIONS.include?(ext)
        extract_from_pdf(file_path)
      elsif TEXT_EXTENSIONS.include?(ext)
        File.read(file_path)
      elsif OFFICE_EXTENSIONS.include?(ext)
        extract_from_office(file_path)
      end
    end

    def supported?(file_path)
      ext = File.extname(file_path).delete('.').downcase
      ALL_EXTENSIONS.include?(ext)
    end

    def pdftotext_path
      SecureView::Config.pdftotext_path || 'pdftotext'
    end

    def extract_from_pdf(file_path)
      stdout, _status = Open3.capture2(pdftotext_path, file_path, '-')
      stdout
    end

    def extract_from_office(file_path)
      Dir.mktmpdir do |temp_dir|
        libreoffice_path = SecureView::Config.libreoffice_path || 'libreoffice'
        system(libreoffice_path, '--headless', '--norestore', '--convert-to', 'pdf',
               '--outdir', temp_dir, file_path, out: File::NULL, err: File::NULL)

        pdf_name = "#{File.basename(file_path, File.extname(file_path))}.pdf"
        pdf_path = File.join(temp_dir, pdf_name)

        return nil unless File.exist?(pdf_path)

        extract_from_pdf(pdf_path)
      end
    end

    private_class_method :extract_from_pdf, :extract_from_office
  end
end
