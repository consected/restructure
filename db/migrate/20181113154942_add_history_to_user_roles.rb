class AddHistoryToUserRoles < ActiveRecord::Migration
  def change
#
reversible do |dir|
  dir.up do

execute <<EOF

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create user_roles app_type_id role_name user_id

CREATE OR REPLACE FUNCTION log_user_role_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO user_role_history
            (
                app_type_id,
                role_name,
                user_id,
                admin_id,
                disabled,
                created_at,
                updated_at,
                user_role_id
                )
            SELECT
                NEW.app_type_id,
                NEW.role_name,
                NEW.user_id,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE user_role_history (
    id integer NOT NULL,
    app_type_id bigint,
    role_name varchar,
    user_id bigint,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    user_role_id integer
);

CREATE SEQUENCE user_role_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE user_role_history_id_seq OWNED BY user_role_history.id;


ALTER TABLE ONLY user_role_history ALTER COLUMN id SET DEFAULT nextval('user_role_history_id_seq'::regclass);

ALTER TABLE ONLY user_role_history
    ADD CONSTRAINT user_role_history_pkey PRIMARY KEY (id);

CREATE INDEX index_user_role_history_on_user_role_id ON user_role_history USING btree (user_role_id);
CREATE INDEX index_user_role_history_on_admin_id ON user_role_history USING btree (admin_id);

CREATE TRIGGER user_role_history_insert AFTER INSERT ON user_roles FOR EACH ROW EXECUTE PROCEDURE log_user_role_update();
CREATE TRIGGER user_role_history_update AFTER UPDATE ON user_roles FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_user_role_update();

ALTER TABLE ONLY user_role_history
    ADD CONSTRAINT fk_user_role_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY user_role_history
    ADD CONSTRAINT fk_user_role_history_user_roles FOREIGN KEY (user_role_id) REFERENCES user_roles(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;

EOF
end
dir.down do

execute <<EOF


DROP TABLE if exists user_role_history CASCADE;
DROP FUNCTION if exists log_user_role_update() CASCADE;

EOF

end
end




  end
end
