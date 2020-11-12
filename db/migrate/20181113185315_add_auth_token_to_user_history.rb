class AddAuthTokenToUserHistory < ActiveRecord::Migration
  def change

#
#
reversible do |dir|
  dir.up do

execute <<EOF

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create page_layouts layout_name panel_name panel_label panel_position options

CREATE OR REPLACE FUNCTION log_user_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO user_history
            (
                email,
                encrypted_password,
                reset_password_token,
                reset_password_sent_at,
                remember_created_at,
                sign_in_count,
                current_sign_in_at,
                last_sign_in_at,
                current_sign_in_ip,
                last_sign_in_ip,
                failed_attempts,
                unlock_token,
                locked_at,
                app_type_id,
                authentication_token,
                admin_id,
                disabled,
                created_at,
                updated_at,
                user_id
                )
            SELECT
                NEW.email,
                NEW.encrypted_password,
                NEW.reset_password_token,
                NEW.reset_password_sent_at,
                NEW.remember_created_at,
                NEW.sign_in_count,
                NEW.current_sign_in_at,
                NEW.last_sign_in_at,
                NEW.current_sign_in_ip,
                NEW.last_sign_in_ip,
                NEW.failed_attempts,
                NEW.unlock_token,
                NEW.locked_at,
                NEW.app_type_id,
                NEW.authentication_token,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;



ALTER TABLE user_history
    ADD COLUMN authentication_token VARCHAR;


EOF
end
dir.down do

execute <<EOF


ALTER TABLE user_history DROP COLUMN authentication_token;

EOF

end
end


  end
end
