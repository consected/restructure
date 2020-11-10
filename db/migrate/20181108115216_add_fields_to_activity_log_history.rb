class AddFieldsToActivityLogHistory < ActiveRecord::Migration
  def change

execute <<EOF

ALTER TABLE activity_log_history
ADD COLUMN blank_log_name varchar,
ADD COLUMN extra_log_types varchar,
ADD COLUMN hide_item_list_panel boolean,
ADD COLUMN main_log_name varchar,
ADD COLUMN process_name varchar,
ADD COLUMN table_name varchar
;


CREATE or REPLACE FUNCTION log_activity_log_update() RETURNS trigger
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
                table_name
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
                NEW.table_name
            ;
            RETURN NEW;
        END;
    $$;

EOF
  end
end
