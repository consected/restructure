class AddHistoryToUserAccessControls < ActiveRecord::Migration
  def change
#
reversible do |dir|
  dir.up do

execute <<EOF

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create user_access_controls user_id resource_type resource_name options access app_type_id role_name

CREATE OR REPLACE FUNCTION log_user_access_control_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO user_access_control_history
            (
                user_id,
                resource_type,
                resource_name,
                options,
                access,
                app_type_id,
                role_name,
                admin_id,
                disabled,
                created_at,
                updated_at,
                user_access_control_id
                )
            SELECT
                NEW.user_id,
                NEW.resource_type,
                NEW.resource_name,
                NEW.options,
                NEW.access,
                NEW.app_type_id,
                NEW.role_name,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE user_access_control_history (
    id integer NOT NULL,
    user_id bigint,
    resource_type varchar,
    resource_name varchar,
    options varchar,
    access varchar,
    app_type_id bigint,
    role_name varchar,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_access_control_id integer
);

CREATE SEQUENCE user_access_control_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE user_access_control_history_id_seq OWNED BY user_access_control_history.id;


ALTER TABLE ONLY user_access_control_history ALTER COLUMN id SET DEFAULT nextval('user_access_control_history_id_seq'::regclass);

ALTER TABLE ONLY user_access_control_history
    ADD CONSTRAINT user_access_control_history_pkey PRIMARY KEY (id);

CREATE INDEX index_user_access_control_history_on_user_access_control_id ON user_access_control_history USING btree (user_access_control_id);
CREATE INDEX index_user_access_control_history_on_admin_id ON user_access_control_history USING btree (admin_id);

CREATE TRIGGER user_access_control_history_insert AFTER INSERT ON user_access_controls FOR EACH ROW EXECUTE PROCEDURE log_user_access_control_update();
CREATE TRIGGER user_access_control_history_update AFTER UPDATE ON user_access_controls FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_user_access_control_update();

ALTER TABLE ONLY user_access_control_history
    ADD CONSTRAINT fk_user_access_control_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY user_access_control_history
    ADD CONSTRAINT fk_user_access_control_history_user_access_controls FOREIGN KEY (user_access_control_id) REFERENCES user_access_controls(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;

EOF
end
dir.down do

execute <<EOF


DROP TABLE if exists user_access_control_history CASCADE;
DROP FUNCTION if exists log_user_access_control_update() CASCADE;

EOF

end
end

    
  end
end
