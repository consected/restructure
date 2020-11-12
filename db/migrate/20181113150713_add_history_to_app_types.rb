class AddHistoryToAppTypes < ActiveRecord::Migration
  def change
#


     reversible do |dir|
       dir.up do

execute <<EOF

 BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create app_types name label

     CREATE OR REPLACE FUNCTION log_app_type_update() RETURNS trigger
         LANGUAGE plpgsql
         AS $$
             BEGIN
                 INSERT INTO app_type_history
                 (
                     name,
                     label,
                     admin_id,
                     disabled,
                     created_at,
                     updated_at,
                     app_type_id
                     )
                 SELECT
                     NEW.name,
                     NEW.label,
                     NEW.admin_id,
                     NEW.disabled,
                     NEW.created_at,
                     NEW.updated_at,
                     NEW.id
                 ;
                 RETURN NEW;
             END;
         $$;

     CREATE TABLE app_type_history (
         id integer NOT NULL,
         name varchar,
         label varchar,
         admin_id integer,
         disabled boolean,
         created_at timestamp without time zone,
         updated_at timestamp without time zone,
         app_type_id integer
     );

     CREATE SEQUENCE app_type_history_id_seq
         START WITH 1
         INCREMENT BY 1
         NO MINVALUE
         NO MAXVALUE
         CACHE 1;

     ALTER SEQUENCE app_type_history_id_seq OWNED BY app_type_history.id;


     ALTER TABLE ONLY app_type_history ALTER COLUMN id SET DEFAULT nextval('app_type_history_id_seq'::regclass);

     ALTER TABLE ONLY app_type_history
         ADD CONSTRAINT app_type_history_pkey PRIMARY KEY (id);

     CREATE INDEX index_app_type_history_on_app_type_id ON app_type_history USING btree (app_type_id);
     CREATE INDEX index_app_type_history_on_admin_id ON app_type_history USING btree (admin_id);

     CREATE TRIGGER app_type_history_insert AFTER INSERT ON app_types FOR EACH ROW EXECUTE PROCEDURE log_app_type_update();
     CREATE TRIGGER app_type_history_update AFTER UPDATE ON app_types FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_app_type_update();

     ALTER TABLE ONLY app_type_history
         ADD CONSTRAINT fk_app_type_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

     ALTER TABLE ONLY app_type_history
         ADD CONSTRAINT fk_app_type_history_app_types FOREIGN KEY (app_type_id) REFERENCES app_types(id);

     GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
     GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
     GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

     COMMIT;

EOF
   end
   dir.down do

execute <<EOF


DROP TABLE if exists app_type_history CASCADE;
DROP FUNCTION if exists log_app_type_update() CASCADE;

EOF

   end
 end




  end
end
