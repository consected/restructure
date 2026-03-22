class RemoveLegacyDeviseTwoFactorSecretsFromAdmins < ActiveRecord::Migration[7.2]
  def change
    remove_column :admins, :encrypted_otp_secret, :string
    remove_column :admins, :encrypted_otp_secret_iv, :string
    remove_column :admins, :encrypted_otp_secret_salt, :string

    remove_column :admin_history, :encrypted_otp_secret, :string
    remove_column :admin_history, :encrypted_otp_secret_iv, :string
    remove_column :admin_history, :encrypted_otp_secret_salt, :string

    add_column :admin_history, :first_name, :string
    add_column :admin_history, :last_name, :string
    add_column :admin_history, :do_not_email, :boolean
    add_column :admin_history, :capabilities, :string, array: true
    add_column :admin_history, :otp_secret, :string

    execute <<~SQL
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
              consumed_timestep,
              otp_required_for_login,
              reset_password_sent_at,
              password_updated_at,
              updated_by_admin_id,
              first_name,
              last_name,
              do_not_email,
              capabilities,
              otp_secret
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
              NEW.consumed_timestep,
              NEW.otp_required_for_login,
              NEW.reset_password_sent_at,
              NEW.password_updated_at,
              NEW.admin_id,
              NEW.first_name,
              NEW.last_name,
              NEW.do_not_email,
              NEW.capabilities,
              NEW.otp_secret
              ;
              RETURN NEW;
          END;
          $$;
    SQL
  end
end
