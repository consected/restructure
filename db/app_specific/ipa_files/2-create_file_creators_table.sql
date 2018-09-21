set search_path=ipa_ops,ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ipa_file_creators first_name last_name email staff_id_no role organization department

      CREATE FUNCTION log_ipa_file_creator_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_file_creator_history
                  (
                      first_name,
                      last_name,
                      email,
                      staff_id_no,
                      role,
                      organization,
                      department,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_file_creator_id
                      )
                  SELECT
                      NEW.first_name,
                      NEW.last_name,
                      NEW.email,
                      NEW.staff_id_no,
                      NEW.role,
                      NEW.organization,
                      NEW.department,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_file_creator_history (
          id integer NOT NULL,
          first_name varchar,
          last_name varchar,
          email varchar,
          staff_id_no varchar,
          role varchar,
          organization varchar,
          department varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_file_creator_id integer
      );

      CREATE SEQUENCE ipa_file_creator_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_file_creator_history_id_seq OWNED BY ipa_file_creator_history.id;

      CREATE TABLE ipa_file_creators (
          id integer NOT NULL,
          first_name varchar,
          last_name varchar,
          email varchar,
          staff_id_no varchar,
          role varchar,
          organization varchar,
          department varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_file_creators_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_file_creators_id_seq OWNED BY ipa_file_creators.id;

      ALTER TABLE ONLY ipa_file_creators ALTER COLUMN id SET DEFAULT nextval('ipa_file_creators_id_seq'::regclass);
      ALTER TABLE ONLY ipa_file_creator_history ALTER COLUMN id SET DEFAULT nextval('ipa_file_creator_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_file_creator_history
          ADD CONSTRAINT ipa_file_creator_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_file_creators
          ADD CONSTRAINT ipa_file_creators_pkey PRIMARY KEY (id);



      CREATE INDEX index_ipa_file_creator_history_on_ipa_file_creator_id ON ipa_file_creator_history USING btree (ipa_file_creator_id);
      CREATE INDEX index_ipa_file_creator_history_on_user_id ON ipa_file_creator_history USING btree (user_id);


      CREATE INDEX index_ipa_file_creators_on_user_id ON ipa_file_creators USING btree (user_id);

      CREATE TRIGGER ipa_file_creator_history_insert AFTER INSERT ON ipa_file_creators FOR EACH ROW EXECUTE PROCEDURE log_ipa_file_creator_update();
      CREATE TRIGGER ipa_file_creator_history_update AFTER UPDATE ON ipa_file_creators FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_file_creator_update();


      ALTER TABLE ONLY ipa_file_creators
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);



      ALTER TABLE ONLY ipa_file_creator_history
          ADD CONSTRAINT fk_ipa_file_creator_history_users FOREIGN KEY (user_id) REFERENCES users(id);





      ALTER TABLE ONLY ipa_file_creator_history
          ADD CONSTRAINT fk_ipa_file_creator_history_ipa_file_creators FOREIGN KEY (ipa_file_creator_id) REFERENCES ipa_file_creators(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
