class UpdateContainerFilesForEmbed < ActiveRecord::Migration[5.2]
  def change
    reversible do |dir|
      dir.up do
        execute <<~END_SQL

          ALTER TABLE nfs_store_stored_files
          ADD COLUMN embed_resource_name varchar, ADD COLUMN embed_resource_id bigint;

          ALTER TABLE nfs_store_archived_files
          ADD COLUMN embed_resource_name varchar, ADD COLUMN embed_resource_id bigint;

          ALTER TABLE nfs_store_stored_file_history
          ADD COLUMN embed_resource_name varchar, ADD COLUMN embed_resource_id bigint;

          ALTER TABLE nfs_store_archived_file_history
          ADD COLUMN embed_resource_name varchar, ADD COLUMN embed_resource_id bigint;

          CREATE or REPLACE FUNCTION log_nfs_store_stored_file_update() RETURNS trigger
              LANGUAGE plpgsql
              AS $$
                  BEGIN
                      INSERT INTO nfs_store_stored_file_history
                      (
                          file_hash,
                          file_name,
                          content_type,
                          path,
                          file_size,
                          file_updated_at,
                          nfs_store_container_id,
                          title,
                          description,
                          file_metadata,
                          last_process_name_run,
                          user_id,
                          created_at,
                          updated_at,
                          nfs_store_stored_file_id,
                          embed_resource_name,
                          embed_resource_id
                          )
                      SELECT
                          NEW.file_hash,
                          NEW.file_name,
                          NEW.content_type,
                          NEW.path,
                          NEW.file_size,
                          NEW.file_updated_at,
                          NEW.nfs_store_container_id,
                          NEW.title,
                          NEW.description,
                          NEW.file_metadata,
                          NEW.last_process_name_run,
                          NEW.user_id,
                          NEW.created_at,
                          NEW.updated_at,
                          NEW.id,
                          NEW.embed_resource_name,
                          NEW.embed_resource_id
                      ;
                      RETURN NEW;
                  END;
              $$;


          CREATE or REPLACE FUNCTION ml_app.log_nfs_store_archived_file_update() RETURNS trigger
              LANGUAGE plpgsql
              AS $$
                  BEGIN
                      INSERT INTO nfs_store_archived_file_history
                      (
                          file_hash,
                          file_name,
                          content_type,
                          archive_file,
                          path,
                          file_size,
                          file_updated_at,
                          nfs_store_container_id,
                          title,
                          description,
                          file_metadata,
                          nfs_store_stored_file_id,
                          user_id,
                          created_at,
                          updated_at,
                          nfs_store_archived_file_id,
                          embed_resource_name,
                          embed_resource_id
                          )
                      SELECT
                          NEW.file_hash,
                          NEW.file_name,
                          NEW.content_type,
                          NEW.archive_file,
                          NEW.path,
                          NEW.file_size,
                          NEW.file_updated_at,
                          NEW.nfs_store_container_id,
                          NEW.title,
                          NEW.description,
                          NEW.file_metadata,
                          NEW.nfs_store_stored_file_id,
                          NEW.user_id,
                          NEW.created_at,
                          NEW.updated_at,
                          NEW.id,
                          NEW.embed_resource_name,
                          NEW.embed_resource_id
                      ;
                      RETURN NEW;
                  END;
              $$;

        END_SQL
      end

      dir.down do
      end
    end
  end
end
