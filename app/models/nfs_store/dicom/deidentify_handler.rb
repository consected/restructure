# frozen_string_literal: true

module NfsStore
  module Dicom
    #
    # Handle the extraction and manipulation of DICOM metadata
    #
    class DeidentifyHandler
      DicomTempFilePrefix = 'nfs-dicom-file'
      attr_accessor :file_path, :dicom_object, :tempfile

      def initialize(file_path: nil)
        self.file_path = file_path
      end

      #
      # Overwrite file metadata with values in a Hash
      # @param [Hash] set_tags represents the values to overwrite individual metadata entries with.
      #    Represented by the form
      #    { tagname: { value: '', enum: true}, 'odd/tagname2': { value: 'some value' }  }
      # @param [Array] delete_tags is the list of tags to delete
      # @return [Tempfile] updated Dicom file stored in a temporary file
      def anonymize_with(set_tags: {}, delete_tags: [], recursive: true)
        anonymizer = DICOM::Anonymizer.new(recursive: recursive)
        anonymizer.reset_defaults(set_tags, delete_tags)

        anonymize(anonymizer)
      end

      #
      # Anonymize file metadata with defaults
      # Setup of anonymizers is explained in http://dicom.github.io/ruby-dicom/tutorial2.html
      # @param [DICOM::Anonymizer | nil] anonymizer is an anonymizer instance, or if nil sets up a default
      # @param [Boolean] recursive indicates if tags should be matched recursively
      # @return [Tempfile] updated Dicom file stored in a temporary file
      def anonymize(anonymizer = nil, recursive: true)
        setup_file
        anonymizer ||= DICOM::Anonymizer.new(recursive: recursive)

        dicom_object.anonymize(anonymizer)

        dicom_object.write(create_tempfile.path)
        tempfile
      end

      private

      # Create a tempfile for output of updated DICOM. Set it in the attribute :tempfile
      # @return [Tempfile]
      def create_tempfile
        self.tempfile = Tempfile.new(DicomTempFilePrefix)
      end

      #
      # Check that the file_path attribute is valid and contains a file
      # Raises an exception if invalid
      def setup_file
        raise FsException::Action, 'No file path for Dicom to extract metadata from' unless file_path
        raise FsException::Action, 'File does not exist for Dicom to extract metadata from' unless File.exist? file_path

        Rails.logger.info "Retrieving file for DICOM metadata processing: #{file_path}"

        self.dicom_object = DICOM::DObject.read(file_path)
      end
    end
  end
end
