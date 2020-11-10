class AddMessageTypeMessageTemplateHistory < ActiveRecord::Migration
  def change

#
reversible do |dir|
  dir.up do

execute <<EOF

    CREATE OR REPLACE FUNCTION log_message_template_update() RETURNS trigger
        LANGUAGE plpgsql
        AS $$
            BEGIN
                INSERT INTO message_template_history
                (
                    name,
                    template_type,
                    message_type,
                    template,
                    admin_id,
                    disabled,
                    created_at,
                    updated_at,
                    message_template_id
                    )
                SELECT
                    NEW.name,
                    NEW.template_type,
                    NEW.message_type,
                    NEW.template,
                    NEW.admin_id,
                    NEW.disabled,
                    NEW.created_at,
                    NEW.updated_at,
                    NEW.id
                ;
                RETURN NEW;
            END;
        $$;


    ALTER TABLE message_template_history
        ADD COLUMN message_type VARCHAR;


EOF
end
dir.down do

execute <<EOF


ALTER TABLE message_template_history DROP COLUMN message_type;

EOF

end
end




  end
end
