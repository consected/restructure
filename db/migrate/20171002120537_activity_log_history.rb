class ActivityLogHistory < ActiveRecord::Migration
  def change
    create_table :activity_log_history do |t|
      t.references :activity_log, index: true, foreign_key: true
      t.string :name
      t.string :item_type
      t.string :rec_type
      t.references :admin
      t.boolean :disabled

      t.timestamps null: false
    end

    reversible do |dir|
      dir.up do
execute <<EOF

        DROP TRIGGER IF EXISTS activity_log_history_insert on activity_logs;
        DROP TRIGGER IF EXISTS activity_log_history_update on activity_logs;
        DROP FUNCTION IF EXISTS log_activity_log_update();
        CREATE FUNCTION log_activity_log_update() RETURNS trigger
            LANGUAGE plpgsql
            AS $$
                BEGIN
                    INSERT INTO activity_log_history
                    (
                        name,
                        activity_log_id,
                        admin_id,
                        created_at,
                        updated_at,
                        item_type,
                        rec_type,
                        disabled
                        )
                    SELECT
                        NEW.name,
                        NEW.id,
                        NEW.admin_id,
                        NEW.created_at,
                        NEW.updated_at,
                        NEW.item_type,
                        NEW.rec_type,
                        NEW.disabled
                    ;
                    RETURN NEW;
                END;
            $$;
            CREATE TRIGGER activity_log_history_insert AFTER INSERT ON activity_logs FOR EACH ROW EXECUTE PROCEDURE log_activity_log_update();
            CREATE TRIGGER activity_log_history_update AFTER UPDATE ON activity_logs FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_update();

EOF
      end
      dir.down do
execute <<EOF

  DROP TRIGGER IF EXISTS activity_log_history_insert on activity_logs;
  DROP TRIGGER IF EXISTS activity_log_history_update on activity_logs;
  DROP FUNCTION IF EXISTS log_activity_log_update();
EOF
      end
    end
  end
end
