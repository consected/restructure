class AddHistoryToAppConfiguration < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do

    execute <<EOF


      BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create app_configurations name value app_type_id user_id role_name

      CREATE or REPLACE FUNCTION log_app_configuration_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO app_configuration_history
                  (
                      name,
                      value,
                      app_type_id,
                      user_id,
                      role_name,
                      admin_id,
                      disabled,
                      created_at,
                      updated_at,
                      app_configuration_id
                      )
                  SELECT
                      NEW.name,
                      NEW.value,
                      NEW.app_type_id,
                      NEW.user_id,
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

      CREATE TABLE app_configuration_history (
          id integer NOT NULL,
          name varchar,
          value varchar,
          app_type_id bigint,
          user_id bigint,
          role_name varchar,
          admin_id integer,
          disabled boolean,
          created_at timestamp without time zone,
          updated_at timestamp without time zone,
          app_configuration_id integer
      );

      CREATE SEQUENCE app_configuration_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE app_configuration_history_id_seq OWNED BY app_configuration_history.id;


      ALTER TABLE ONLY app_configuration_history ALTER COLUMN id SET DEFAULT nextval('app_configuration_history_id_seq'::regclass);

      ALTER TABLE ONLY app_configuration_history
          ADD CONSTRAINT app_configuration_history_pkey PRIMARY KEY (id);

      CREATE INDEX index_app_configuration_history_on_app_configuration_id ON app_configuration_history USING btree (app_configuration_id);
      CREATE INDEX index_app_configuration_history_on_admin_id ON app_configuration_history USING btree (admin_id);

      CREATE TRIGGER app_configuration_history_insert AFTER INSERT ON app_configurations FOR EACH ROW EXECUTE PROCEDURE log_app_configuration_update();
      CREATE TRIGGER app_configuration_history_update AFTER UPDATE ON app_configurations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_app_configuration_update();

      ALTER TABLE ONLY app_configuration_history
          ADD CONSTRAINT fk_app_configuration_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

      ALTER TABLE ONLY app_configuration_history
          ADD CONSTRAINT fk_app_configuration_history_app_configurations FOREIGN KEY (app_configuration_id) REFERENCES app_configurations(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;


EOF
      end
      dir.down do

execute <<EOF


  DROP TABLE if exists app_configuration_history CASCADE;
  DROP FUNCTION if exists log_app_configuration_update() CASCADE;

EOF

      end
    end


  end
end
