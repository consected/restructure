class AlterUserAndAdminHistory < ActiveRecord::Migration
  def change
    execute <<EOF

    alter table ml_app.user_history
    add column encrypted_otp_secret character varying,
    add column encrypted_otp_secret_iv character varying,
    add column encrypted_otp_secret_salt character varying,
    add column consumed_timestep integer,
    add column otp_required_for_login boolean,
    add column password_updated_at timestamp without time zone,
    add column first_name varchar,
    add column last_name varchar
    ;

    CREATE OR REPLACE FUNCTION ml_app.log_user_update()
     RETURNS trigger
     LANGUAGE plpgsql
    AS $function$
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
            last_name
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
            NEW.last_name
            ;
            RETURN NEW;
        END;
    $function$;


    alter table ml_app.admin_history
    add column encrypted_otp_secret character varying,
    add column encrypted_otp_secret_iv character varying,
    add column encrypted_otp_secret_salt character varying,
    add column consumed_timestep integer,
    add column otp_required_for_login boolean,
    add column reset_password_sent_at timestamp without time zone,
    add column password_updated_at timestamp without time zone
    ;


    CREATE OR REPLACE FUNCTION ml_app.log_admin_update()
     RETURNS trigger
     LANGUAGE plpgsql
    AS $function$
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
        password_updated_at

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
        NEW.password_updated_at
        ;
        RETURN NEW;
    END;
    $function$;


EOF
  end
end
