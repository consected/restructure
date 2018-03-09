
      BEGIN;

      CREATE FUNCTION log_ipa_navigator_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ipa_navigator_history
                  (
                      master_id,
                      select_navigator,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ipa_navigator_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_navigator,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ipa_navigator_history (
          id integer NOT NULL,
          master_id integer,
          select_navigator varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ipa_navigator_id integer
      );

      CREATE SEQUENCE ipa_navigator_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_navigator_history_id_seq OWNED BY ipa_navigator_history.id;

      CREATE TABLE ipa_navigators (
          id integer NOT NULL,
          master_id integer,
          select_navigator varchar,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ipa_navigators_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ipa_navigators_id_seq OWNED BY ipa_navigators.id;

      ALTER TABLE ONLY ipa_navigators ALTER COLUMN id SET DEFAULT nextval('ipa_navigators_id_seq'::regclass);
      ALTER TABLE ONLY ipa_navigator_history ALTER COLUMN id SET DEFAULT nextval('ipa_navigator_history_id_seq'::regclass);

      ALTER TABLE ONLY ipa_navigator_history
          ADD CONSTRAINT ipa_navigator_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ipa_navigators
          ADD CONSTRAINT ipa_navigators_pkey PRIMARY KEY (id);

      CREATE INDEX index_ipa_navigator_history_on_master_id ON ipa_navigator_history USING btree (master_id);


      CREATE INDEX index_ipa_navigator_history_on_ipa_navigator_id ON ipa_navigator_history USING btree (ipa_navigator_id);
      CREATE INDEX index_ipa_navigator_history_on_user_id ON ipa_navigator_history USING btree (user_id);

      CREATE INDEX index_ipa_navigators_on_master_id ON ipa_navigators USING btree (master_id);

      CREATE INDEX index_ipa_navigators_on_user_id ON ipa_navigators USING btree (user_id);

      CREATE TRIGGER ipa_navigator_history_insert AFTER INSERT ON ipa_navigators FOR EACH ROW EXECUTE PROCEDURE log_ipa_navigator_update();
      CREATE TRIGGER ipa_navigator_history_update AFTER UPDATE ON ipa_navigators FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_ipa_navigator_update();


      ALTER TABLE ONLY ipa_navigators
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ipa_navigators
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ipa_navigator_history
          ADD CONSTRAINT fk_ipa_navigator_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ipa_navigator_history
          ADD CONSTRAINT fk_ipa_navigator_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ipa_navigator_history
          ADD CONSTRAINT fk_ipa_navigator_history_ipa_navigators FOREIGN KEY (ipa_navigator_id) REFERENCES ipa_navigators(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
