class RemoveLegacyDeviseTwoFactorSecretsFromUsers < ActiveRecord::Migration[7.2]
  def change
    remove_column :users, :encrypted_otp_secret, :string
    remove_column :users, :encrypted_otp_secret_iv, :string
    remove_column :users, :encrypted_otp_secret_salt, :string

    remove_column :user_history, :encrypted_otp_secret, :string
    remove_column :user_history, :encrypted_otp_secret_iv, :string
    remove_column :user_history, :encrypted_otp_secret_salt, :string

    add_column :user_history, :do_not_email, :boolean
    add_column :user_history, :otp_secret, :string
    add_column :user_history, :country_code, :string
    add_column :user_history, :terms_of_use_accepted, :string

    execute <<~SQL
      CREATE OR REPLACE FUNCTION ml_app.log_user_update() RETURNS trigger
      LANGUAGE plpgsql
      AS $$
      BEGIN
        INSERT INTO user_history
        (
            user_id,
            email,
            encrypted_password,
            reset_password_token,
            reset_password_sent_at,
            remember_created_at,
            sign_in_count,
            current_sign_in_at,
            last_sign_in_at,
            current_sign_in_ip ,
            last_sign_in_ip ,
            created_at,
            updated_at,
            failed_attempts,
            unlock_token,
            locked_at,
            disabled,
            admin_id,
            app_type_id,
            authentication_token,
            consumed_timestep,
            otp_required_for_login,
            password_updated_at,
            first_name,
            last_name,
            confirmation_token,
            confirmed_at,
            confirmation_sent_at,
            do_not_email,
            country_code,
            terms_of_use_accepted,
            otp_secret
        )
        SELECT
          NEW.id,
          NEW.email,
          NEW.encrypted_password,
          NEW.reset_password_token,
          NEW.reset_password_sent_at,
          NEW.remember_created_at,
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
          NEW.disabled ,
          NEW.admin_id,
          NEW.app_type_id,
          NEW.authentication_token,
          NEW.consumed_timestep,
          NEW.otp_required_for_login,
          NEW.password_updated_at,
          NEW.first_name,
          NEW.last_name,
          NEW.confirmation_token,
          NEW.confirmed_at,
          NEW.confirmation_sent_at,
          NEW.do_not_email,
          NEW.country_code,
          NEW.terms_of_use_accepted,
          NEW.otp_secret
        ;
        RETURN NEW;
        END;
        $$;
    SQL
  end
end
