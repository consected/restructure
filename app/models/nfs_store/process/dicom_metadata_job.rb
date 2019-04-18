module NfsStore
  module Process
    class DicomMetadataJob < ApplicationJob

      # retry_on FphsException
      queue_as :nfs_store_process

      # Check whether the job should be enqueued or just skipped
      around_enqueue do |job, block|

        container_file = job.arguments.first

        if container_file.content_type == 'application/dicom' || container_file.is_archive?
          block.call
        else
          container_file = job.arguments.first
          ProcessHandler.new(container_file).run_next_job_after 'dicom_metadata'
        end
      end

      after_perform do |job|
        container_file = job.arguments.first
        ProcessHandler.new(container_file).run_next_job_after 'dicom_metadata'
      end

      def perform(container_file)


        puts "Extracting DICOM metadata for #{container_file}"

        if container_file.is_archive?
          container_file.current_user = container_file.user
          afs = container_file.archived_files.all
          afs.each do |af|
            extract_metadata af unless af.content_type.blank?
          end
        else
          extract_metadata container_file unless container_file.content_type.blank?
        end


      end

      def extract_metadata container_file

        container_file.current_user = container_file.user
        full_path = container_file.retrieval_path
        return if container_file.content_type.blank?

        mh = NfsStore::Dicom::MetadataHandler.new(file_path: full_path)
        metadata = mh.extract_metadata
        container_file.file_metadata = metadata
        container_file.save!

      end
    end
  end
end
