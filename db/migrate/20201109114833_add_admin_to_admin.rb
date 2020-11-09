class AddAdminToAdmin < ActiveRecord::Migration[5.2]
  def change
    add_reference :admins, :admin, foreign_key: true

    execute <<~END_SQL
      ALTER TABLE ml_app.admin_history add column updated_by_admin_id integer;   

      CREATE INDEX index_admin_history_on_upd_admin_id ON ml_app.admin_history USING btree (updated_by_admin_id);

      ALTER TABLE ONLY ml_app.admin_history
        ADD CONSTRAINT fk_admin_history_upd_admins FOREIGN KEY (updated_by_admin_id) REFERENCES ml_app.admins(id);

      CREATE OR REPLACE FUNCTION ml_app.log_admin_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
          BEGIN
            INSERT INTO admin_history
            (
              admin_id,
              email,
              encrypted_password,
              sign_in_count,
              current_sign_in_at,
              last_sign_in_at,
              current_sign_in_ip ,
              last_sign_in_ip ,
              created_at ,
              updated_at,
              failed_attempts,
              unlock_token,
              locked_at,
              disabled,
              encrypted_otp_secret,
              encrypted_otp_secret_iv,
              encrypted_otp_secret_salt,
              consumed_timestep,
              otp_required_for_login,
              reset_password_sent_at,
              password_updated_at,
              updated_by_admin_id

            )
            SELECT
              NEW.id,
              NEW.email,
              NEW.encrypted_password,
              NEW.sign_in_count,
              NEW.current_sign_in_at,
              NEW.last_sign_in_at,
              NEW.current_sign_in_ip ,
              NEW.last_sign_in_ip ,
              NEW.created_at ,
              NEW.updated_at,
              NEW.failed_attempts,
              NEW.unlock_token,
              NEW.locked_at,
              NEW.disabled,
              NEW.encrypted_otp_secret,
              NEW.encrypted_otp_secret_iv,
              NEW.encrypted_otp_secret_salt,
              NEW.consumed_timestep,
              NEW.otp_required_for_login,
              NEW.reset_password_sent_at,
              NEW.password_updated_at,
              NEW.admin_id
              ;
              RETURN NEW;
          END;
          $$;

    END_SQL
  end
end
