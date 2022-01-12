# frozen_string_literal: true

class AddConfirmableToDevise < ActiveRecord::Migration[5.2]
  # NOTE: You can't use change, as User.update_all will fail in the down migration
  def up
    add_column :users, :confirmation_token, :string
    add_column :users, :confirmed_at, :datetime
    add_column :users, :confirmation_sent_at, :datetime

    add_column :user_history, :confirmation_token, :string
    add_column :user_history, :confirmed_at, :datetime
    add_column :user_history, :confirmation_sent_at, :datetime

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
            created_at ,
            updated_at,
            failed_attempts,
            unlock_token,
            locked_at,
            disabled ,
            admin_id,
            app_type_id,
            authentication_token,
            encrypted_otp_secret,
            encrypted_otp_secret_iv,
            encrypted_otp_secret_salt,
            consumed_timestep,
            otp_required_for_login,
            password_updated_at,
            first_name,
            last_name,
            confirmation_token,
            confirmed_at,
            confirmation_sent_at
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
          NEW.encrypted_otp_secret,
          NEW.encrypted_otp_secret_iv,
          NEW.encrypted_otp_secret_salt,
          NEW.consumed_timestep,
          NEW.otp_required_for_login,
          NEW.password_updated_at,
          NEW.first_name,
          NEW.last_name,
          NEW.confirmation_token,
          NEW.confirmed_at,
          NEW.confirmation_sent_at
        ;
        RETURN NEW;
        END;
        $$;
    SQL

    epic_confirmation_datetime = DateTime.now
    User.active.update_all(confirmed_at: epic_confirmation_datetime)

    add_index :users, :confirmation_token, unique: true
  end

  def down
    remove_index :users, :confirmation_token
    remove_columns :user_history, :confirmation_token, :confirmed_at, :confirmation_sent_at
    remove_columns :users, :confirmation_token, :confirmed_at, :confirmation_sent_at
  end
end
