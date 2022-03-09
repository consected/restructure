class AddCreatedByUserToNfsStoreContainers < ActiveRecord::Migration[5.2]
  def change
    add_reference :nfs_store_containers, :created_by_user, foreign_key: { to_table: 'users' }
    add_reference :nfs_store_container_history, :created_by_user, foreign_key: { to_table: 'users' }

    execute <<~END_SQL
      CREATE OR REPLACE FUNCTION ml_app.log_nfs_store_container_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO nfs_store_container_history
                  (
                      master_id,
                      name,
                      app_type_id,
                      orig_nfs_store_container_id,
                      created_by_user_id,
                      user_id,
                      created_at,
                      updated_at,
                      nfs_store_container_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.name,
                      NEW.app_type_id,
                      NEW.nfs_store_container_id,
                      NEW.created_by_user_id,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

    END_SQL
  end
end
