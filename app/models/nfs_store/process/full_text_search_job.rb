# frozen_string_literal: true

module NfsStore
  module Process
    class FullTextSearchJob < NfsStoreJob
      queue_as :nfs_store_process

      flow_control :full_text_search,
                   skip_if: lambda { |container_file|
                     container_file.is_a?(NfsStore::Manage::ContainerFile) &&
                       !FullTextSearch::TextExtractor.supported?(container_file.file_name)
                   }

      def perform(container_files, in_app_type_id, activity_log = nil, call_options = {})
        log 'Running Full Text Search Job'

        container_files = [container_files] if container_files.is_a? NfsStore::Manage::ContainerFile

        container_files.each do |container_file|
          container = container_file.container
          container.parent_item ||= activity_log

          config = NfsStore::Process::ProcessHandler.new(container_file,
                                                         call_options).pipeline_job_config(:full_text_search)
          next unless config

          setup_container_file_current_user(container_file, in_app_type_id) do |_c_user|
            process_file(container_file, config)
          end
        end
      end

      private

      def process_file(container_file, config)
        filters = config[:file_filters]
        return unless passes_file_filters?(container_file, filters)

        file_path = container_file.retrieval_path
        return unless file_path && FullTextSearch::TextExtractor.supported?(file_path)

        text_content = FullTextSearch::TextExtractor.extract_text(file_path)
        return if text_content.blank?

        target_table = config[:target_table]
        target_field = config[:target_column]
        fk_column = config[:target_foreign_key_column]
        ts_config = config[:ts_config] || 'english'

        return unless target_table && target_field && fk_column

        FullTextSearch::TsvectorWriter.write_tsvector(
          target_table: target_table,
          target_field: target_field,
          text_content: text_content,
          fk_column: fk_column,
          fk_value: container_file.id,
          ts_config: ts_config
        )
      end

      def passes_file_filters?(container_file, filters)
        return true if filters.blank?

        filtered_files = NfsStore::Filter::Filter.evaluate_container_files_as_scopes(
          container_file.container,
          filters: filters
        )
        return false unless filtered_files

        if container_file.is_a?(NfsStore::Manage::ArchivedFile)
          filtered_files[:archived_files].where(id: container_file.id).exists?
        else
          filtered_files[:stored_files].where(id: container_file.id).exists?
        end
      end
    end
  end
end
