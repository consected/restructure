set search_path=grit, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create grit_secure_notes notes

      CREATE FUNCTION log_grit_secure_note_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO grit_secure_note_history
                  (
                      master_id,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      grit_secure_note_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE grit_secure_note_history (
          id integer NOT NULL,
          master_id integer,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          grit_secure_note_id integer
      );

      CREATE SEQUENCE grit_secure_note_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_secure_note_history_id_seq OWNED BY grit_secure_note_history.id;

      CREATE TABLE grit_secure_notes (
          id integer NOT NULL,
          master_id integer,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE grit_secure_notes_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE grit_secure_notes_id_seq OWNED BY grit_secure_notes.id;

      ALTER TABLE ONLY grit_secure_notes ALTER COLUMN id SET DEFAULT nextval('grit_secure_notes_id_seq'::regclass);
      ALTER TABLE ONLY grit_secure_note_history ALTER COLUMN id SET DEFAULT nextval('grit_secure_note_history_id_seq'::regclass);

      ALTER TABLE ONLY grit_secure_note_history
          ADD CONSTRAINT grit_secure_note_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY grit_secure_notes
          ADD CONSTRAINT grit_secure_notes_pkey PRIMARY KEY (id);

      CREATE INDEX index_grit_secure_note_history_on_master_id ON grit_secure_note_history USING btree (master_id);


      CREATE INDEX index_grit_secure_note_history_on_grit_secure_note_id ON grit_secure_note_history USING btree (grit_secure_note_id);
      CREATE INDEX index_grit_secure_note_history_on_user_id ON grit_secure_note_history USING btree (user_id);

      CREATE INDEX index_grit_secure_notes_on_master_id ON grit_secure_notes USING btree (master_id);

      CREATE INDEX index_grit_secure_notes_on_user_id ON grit_secure_notes USING btree (user_id);

      CREATE TRIGGER grit_secure_note_history_insert AFTER INSERT ON grit_secure_notes FOR EACH ROW EXECUTE PROCEDURE log_grit_secure_note_update();
      CREATE TRIGGER grit_secure_note_history_update AFTER UPDATE ON grit_secure_notes FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_grit_secure_note_update();


      ALTER TABLE ONLY grit_secure_notes
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY grit_secure_notes
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY grit_secure_note_history
          ADD CONSTRAINT fk_grit_secure_note_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY grit_secure_note_history
          ADD CONSTRAINT fk_grit_secure_note_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY grit_secure_note_history
          ADD CONSTRAINT fk_grit_secure_note_history_grit_secure_notes FOREIGN KEY (grit_secure_note_id) REFERENCES grit_secure_notes(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
