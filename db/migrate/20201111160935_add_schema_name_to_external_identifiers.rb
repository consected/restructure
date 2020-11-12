class AddSchemaNameToExternalIdentifiers < ActiveRecord::Migration[5.2]
  def change
    add_column :external_identifiers, :schema_name, :string

    execute <<~END_SQL

      ALTER TABLE external_identifier_history ADD COLUMN schema_name varchar;

      CREATE OR REPLACE FUNCTION ml_app.log_external_identifier_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO external_identifier_history
                (
                    name,
                    label,
                    external_id_attribute,
                    external_id_view_formatter,
                    external_id_edit_pattern,
                    prevent_edit,
                    pregenerate_ids,
                    min_id,
                    max_id,
                    alphanumeric,
                    extra_fields,
                    admin_id,
                    disabled,
                    created_at,
                    updated_at,
                    external_identifier_id,
                    schema_name
                    )
                SELECT
                    NEW.name,
                    NEW.label,
                    NEW.external_id_attribute,
                    NEW.external_id_view_formatter,
                    NEW.external_id_edit_pattern,
                    NEW.prevent_edit,
                    NEW.pregenerate_ids,
                    NEW.min_id,
                    NEW.max_id,
                    NEW.alphanumeric,
                    NEW.extra_fields,
                    NEW.admin_id,
                    NEW.disabled,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id,
                    NEW.schema_name
                ;
                RETURN NEW;
            END;
        $$;


    END_SQL
  end
end
