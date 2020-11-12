class AddAppTypeToPageLayoutHistory < ActiveRecord::Migration
  def change

    #
    reversible do |dir|
      dir.up do

    execute <<EOF

    BEGIN;

    -- Command line:
    -- table_generators/generate.sh admin_history_table create page_layouts layout_name panel_name panel_label panel_position options

    CREATE OR REPLACE FUNCTION log_page_layout_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO page_layout_history
                (
                    app_type_id,
                    layout_name,
                    panel_name,
                    panel_label,
                    panel_position,
                    options,
                    admin_id,
                    disabled,
                    created_at,
                    updated_at,
                    page_layout_id
                    )
                SELECT
                    NEW.app_type_id,
                    NEW.layout_name,
                    NEW.panel_name,
                    NEW.panel_label,
                    NEW.panel_position,
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


    ALTER TABLE page_layout_history
        ADD COLUMN app_type_id VARCHAR;


EOF
end
dir.down do

execute <<EOF


ALTER TABLE page_layout_history DROP COLUMN app_type_id;

EOF

end
end


  end
end
