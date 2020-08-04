# Migration version added
class CreateConfigLibrary < ActiveRecord::Migration[4.2]
  def change
    create_table :config_libraries do |t|
      t.string :category
      t.string :name
      t.string :options
      t.string :format
      t.boolean :disabled, default: false
      t.belongs_to :admin, index: true, foreign_key: true
      t.timestamps

    end

    create_table :config_library_history do |t|
      t.string :category
      t.string :name
      t.string :options
      t.string :format
      t.boolean :disabled, default: false
      t.belongs_to :admin, index: true, foreign_key: true
      t.belongs_to :config_library, index: true, foreign_key: true
      t.timestamps
    end


    reversible do |dir|
      dir.up do
execute <<EOF

CREATE OR REPLACE FUNCTION ml_app.log_config_library_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO config_library_history
            (
                    config_library_id,
                    category,
                    name,
                    options,
                    format,
                    disabled,
                    admin_id,
                    updated_at,
                    created_at
                )
            SELECT
                NEW.id,
                NEW.category,
                NEW.name,
                NEW.options,
                NEW.format,
                NEW.disabled,
                NEW.admin_id,
                NEW.updated_at,
                NEW.created_at
            ;
            RETURN NEW;
        END;
    $$;


  CREATE TRIGGER config_library_history_insert AFTER INSERT ON ml_app.config_libraries FOR EACH ROW EXECUTE PROCEDURE ml_app.log_config_library_update();
  CREATE TRIGGER config_library_history_update AFTER UPDATE ON ml_app.config_libraries FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE ml_app.log_config_library_update();

EOF
      end
      dir.down do
execute <<EOF
        DROP FUNCTION ml_app.log_config_library_update() cascade;
EOF
      end
    end


  end
end
