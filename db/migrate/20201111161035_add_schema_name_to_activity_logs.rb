class AddSchemaNameToActivityLogs < ActiveRecord::Migration[5.2]
  def change
    add_column :activity_logs, :schema_name, :string

    execute <<~END_SQL

      ALTER TABLE activity_log_history ADD COLUMN schema_name varchar;

      CREATE OR REPLACE FUNCTION ml_app.log_activity_log_update() RETURNS trigger
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
                      disabled,
                      action_when_attribute,
                      field_list,
                      blank_log_field_list,
                      blank_log_name,
                      extra_log_types,
                      hide_item_list_panel,
                      main_log_name,
                      process_name,
                      table_name,
                      category,
                      schema_name
                      )
                  SELECT
                      NEW.name,
                      NEW.id,
                      NEW.admin_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.item_type,
                      NEW.rec_type,
                      NEW.disabled,
                      NEW.action_when_attribute,
                      NEW.field_list,
                      NEW.blank_log_field_list,
                      NEW.blank_log_name,
                      NEW.extra_log_types,
                      NEW.hide_item_list_panel,
                      NEW.main_log_name,
                      NEW.process_name,
                      NEW.table_name,
                      NEW.category,
                      NEW.schema_name
                  ;
                  RETURN NEW;
              END;
          $$;

    END_SQL
  end
end
