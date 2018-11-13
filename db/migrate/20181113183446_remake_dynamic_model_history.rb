class RemakeDynamicModelHistory < ActiveRecord::Migration
  def change

    reversible do |dir|
      dir.up do

execute <<EOF

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create dynamic_models name table_name schema_name primary_key_name foreign_key_name description position category table_key_name field_list result_order options

    CREATE OR REPLACE FUNCTION log_dynamic_model_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO dynamic_model_history
                (
                    name,
                    table_name,
                    schema_name,
                    primary_key_name,
                    foreign_key_name,
                    description,
                    position,
                    category,
                    table_key_name,
                    field_list,
                    result_order,
                    options,
                    admin_id,
                    disabled,
                    created_at,
                    updated_at,
                    dynamic_model_id
                    )
                SELECT
                    NEW.name,
                    NEW.table_name,
                    NEW.schema_name,
                    NEW.primary_key_name,
                    NEW.foreign_key_name,
                    NEW.description,
                    NEW.position,
                    NEW.category,
                    NEW.table_key_name,
                    NEW.field_list,
                    NEW.result_order,
                    NEW.options,
                    NEW.admin_id,
                    NEW.disabled,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id
                ;
                RETURN NEW;
            END;
        $$;

    ALTER TABLE dynamic_model_history
        ADD COLUMN options varchar;


    COMMIT;

EOF
  end
  dir.down do

execute <<EOF


ALTER TABLE  dynamic_model_history DROP COLUMN  options varchar;

EOF

  end
end




  end
end
