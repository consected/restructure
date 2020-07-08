# frozen_string_literal: true

class GenNewFilestoreReportFunctions < ActiveRecord::Migration[4.2]
  def change
    execute <<~EOF

      CREATE OR REPLACE FUNCTION ml_app.filestore_report_full_file_path(sf nfs_store_stored_files, af nfs_store_archived_files) RETURNS VARCHAR AS $$
          BEGIN

            return CASE WHEN af.id IS NOT NULL THEN
              coalesce(sf.path, '') || '/' || sf.file_name || '/' || af.path || '/' || af.file_name
              ELSE coalesce(sf.path, '') || '/' || sf.file_name
            END;

      	END;
      $$ LANGUAGE plpgsql;

    EOF
  end
end
