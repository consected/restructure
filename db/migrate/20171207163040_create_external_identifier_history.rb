class CreateExternalIdentifierHistory < ActiveRecord::Migration
  def change
    create_table :external_identifier_history do |t|
      t.string :name
      t.string :label
      t.string :external_id_attribute
      t.string :external_id_view_formatter
      t.string :external_id_edit_pattern
      t.boolean :prevent_edit
      t.boolean :pregenerate_ids
      t.integer :min_id, limit: 8
      t.integer :max_id, limit: 8

      t.belongs_to :admin, index: true, foreign_key: true
      t.boolean :disabled
      t.timestamps null: false
      t.references :external_identifier, index: true, foreign_key: true
    end

    reversible do |dir|
      dir.up do
execute <<EOF

        DROP TRIGGER IF EXISTS external_identifier_history_insert on external_identifiers;
        DROP TRIGGER IF EXISTS external_identifier_history_update on external_identifiers;
        DROP FUNCTION IF EXISTS log_external_identifier_update();
        CREATE FUNCTION log_external_identifier_update() RETURNS trigger
            LANGUAGE plpgsql
            AS $$
                BEGIN
                    INSERT INTO external_identifier_history
                    (
                        name,
                        external_identifier_id,
                        label,
                        external_id_attribute,
                        external_id_view_formatter,
                        external_id_edit_pattern,
                        prevent_edit,
                        pregenerate_ids,
                        min_id,
                        max_id,
                        admin_id,
                        created_at,
                        updated_at,
                        disabled
                        )
                    SELECT
                        NEW.name,
                        NEW.id,
                        NEW.label,
                        NEW.external_id_attribute,
                        NEW.external_id_view_formatter,
                        NEW.external_id_edit_pattern,
                        NEW.prevent_edit,
                        NEW.pregenerate_ids,
                        NEW.min_id,
                        NEW.max_id,
                        NEW.admin_id,
                        NEW.created_at,
                        NEW.updated_at,
                        NEW.disabled
                    ;
                    RETURN NEW;
                END;
            $$;
            CREATE TRIGGER external_identifier_history_insert AFTER INSERT ON external_identifiers FOR EACH ROW EXECUTE PROCEDURE log_external_identifier_update();
            CREATE TRIGGER external_identifier_history_update AFTER UPDATE ON external_identifiers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_external_identifier_update();

EOF
      end
      dir.down do
execute <<EOF

  DROP TRIGGER IF EXISTS external_identifier_history_insert on external_identifiers;
  DROP TRIGGER IF EXISTS external_identifier_history_update on external_identifiers;
  DROP FUNCTION IF EXISTS log_external_identifier_update();
EOF
      end
    end
  end
end
