# frozen_string_literal: true

module NfsStore
  module Dicom
    #
    # Handle the extraction and manipulation of DICOM metadata
    #
    class DeidentifyHandler
      DicomTempFilePrefix = 'nfs-dicom-file'
      attr_accessor :file_path, :dicom_object, :tempfile

      # Use the pipeline configuration to deidentify metadata in a Dicom file, relying
      # on the extra log type configuration
      # @param [NfsStore::Manage::ContainerFile] container_file represents a stored or archived file
      # @param [Hash] config containing :set_tags and :delete_tags
      #    {
      #      set_tags: { "0010,0010" => "some value", "0010,0020" => "another value" },
      #      delete_tags: ["0020,0080"]
      #    }
      def self.deidentify_file(container_file, config)
        container_file.current_user = container_file.user
        return if container_file.content_type.blank?

        full_path = container_file.retrieval_path

        set_tags = config[:set_tags]
        # Handle substitutions of new values
        set_tags.each_key do |k|
          v = Admin::MessageTemplate.substitute(set_tags[k], data: container_file, tag_subs: nil)
          set_tags[k] = v
        end
        delete_tags = config[:delete_tags]

        # Overwrite the metadata
        dh = DeidentifyHandler.new(file_path: full_path)
        new_tmp_image_path = dh.anonymize_with(set_tags: set_tags, delete_tags: delete_tags)

        new_path = config[:new_path]
        if new_path
          attrs = container_file.attributes
          attrs['path'] = new_path
          attrs['do_not_postprocess'] = true
          container_file = container_file.class.store_new_file(new_tmp_image_path, container_file.container, attrs)
        else
          container_file.replace_file! new_tmp_image_path
        end

        if container_file.file_metadata.present?
          # There is existing metadata stored. Bring it up to date based on the updated file
          dmj = NfsStore::Process::DicomMetadataJob.new
          dmj.extract_metadata(container_file)
        end
      end

      #
      # Overwrite file metadata with values in a Hash
      # @param [Hash] set_tags represents the values to overwrite individual metadata entries with.
      #    Represented by the form
      #    { tagname: { value: '', enum: true}, 'odd/tagname2': { value: 'some value' }  }
      # @param [Array] delete_tags is the list of tags to delete
      # @return [String] updated Dicom file path
      def anonymize_with(set_tags: {}, delete_tags: [], recursive: true)
        anonymizer = DICOM::Anonymizer.new(recursive: recursive)
        anonymizer.reset_defaults(set_tags, delete_tags)

        anonymize(anonymizer)
      end

      protected

      def initialize(file_path: nil)
        self.file_path = file_path
      end

      #
      # Anonymize file metadata with defaults
      # Setup of anonymizers is explained in http://dicom.github.io/ruby-dicom/tutorial2.html
      # @param [DICOM::Anonymizer | nil] anonymizer is an anonymizer instance, or if nil sets up a default
      # @param [Boolean] recursive indicates if tags should be matched recursively
      # @return [String] updated Dicom file path
      def anonymize(anonymizer = nil, recursive: true)
        setup_file
        anonymizer ||= DICOM::Anonymizer.new(recursive: recursive)

        dicom_object.anonymize(anonymizer)

        dicom_object.write(output_path)
        output_path
      end

      private

      def output_path
        return tempfile if tempfile

        tmpdir = Manage::Filesystem.temp_directory
        self.tempfile = File.join(tmpdir, "#{DicomTempFilePrefix}-#{rand(10)}.dcm")
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
