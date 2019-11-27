set search_path=grit, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh activity_logs_table create activity_log_grit_assignment_discussions grit_assignment tag_select_contact_role notes prev_activity_type

      CREATE TABLE activity_log_grit_assignment_discussion_history (
          id integer NOT NULL,
          master_id integer,
          grit_assignment_id integer,
          tag_select_contact_role varchar[],
          notes varchar,
          prev_activity_type varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_grit_assignment_discussion_id integer
      );
      CREATE TABLE activity_log_grit_assignment_discussions (
          id integer NOT NULL,
          master_id integer,
          grit_assignment_id integer,
          tag_select_contact_role varchar[],
          notes varchar,
          prev_activity_type varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE OR REPLACE FUNCTION log_activity_log_grit_assignment_discussion_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_grit_assignment_discussion_history
                  (
                      master_id,
                      grit_assignment_id,
                      tag_select_contact_role,
                      notes,
                      prev_activity_type,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_grit_assignment_discussion_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.grit_assignment_id,
                      NEW.tag_select_contact_role,
                      NEW.notes,
                      NEW.prev_activity_type,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE SEQUENCE activity_log_grit_assignment_discussion_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_grit_assignment_discussion_history_id_seq OWNED BY activity_log_grit_assignment_discussion_history.id;


      CREATE SEQUENCE activity_log_grit_assignment_discussions_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_grit_assignment_discussions_id_seq OWNED BY activity_log_grit_assignment_discussions.id;

      ALTER TABLE ONLY activity_log_grit_assignment_discussions ALTER COLUMN id SET DEFAULT nextval('activity_log_grit_assignment_discussions_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_grit_assignment_discussion_history ALTER COLUMN id SET DEFAULT nextval('activity_log_grit_assignment_discussion_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_grit_assignment_discussion_history
          ADD CONSTRAINT activity_log_grit_assignment_discussion_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_grit_assignment_discussions
          ADD CONSTRAINT activity_log_grit_assignment_discussions_pkey PRIMARY KEY (id);

      CREATE INDEX index_al_grit_assignment_discussion_history_on_master_id ON activity_log_grit_assignment_discussion_history USING btree (master_id);
      CREATE INDEX index_al_grit_assignment_discussion_history_on_grit_assignment_discussion_id ON activity_log_grit_assignment_discussion_history USING btree (grit_assignment_id);

      CREATE INDEX index_al_grit_assignment_discussion_history_on_activity_log_grit_assignment_discussion_id ON activity_log_grit_assignment_discussion_history USING btree (activity_log_grit_assignment_discussion_id);
      CREATE INDEX index_al_grit_assignment_discussion_history_on_user_id ON activity_log_grit_assignment_discussion_history USING btree (user_id);

      CREATE INDEX index_activity_log_grit_assignment_discussions_on_master_id ON activity_log_grit_assignment_discussions USING btree (master_id);
      CREATE INDEX index_activity_log_grit_assignment_discussions_on_grit_assignment_discussion_id ON activity_log_grit_assignment_discussions USING btree (grit_assignment_id);
      CREATE INDEX index_activity_log_grit_assignment_discussions_on_user_id ON activity_log_grit_assignment_discussions USING btree (user_id);

      CREATE TRIGGER activity_log_grit_assignment_discussion_history_insert AFTER INSERT ON activity_log_grit_assignment_discussions FOR EACH ROW EXECUTE PROCEDURE log_activity_log_grit_assignment_discussion_update();
      CREATE TRIGGER activity_log_grit_assignment_discussion_history_update AFTER UPDATE ON activity_log_grit_assignment_discussions FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_grit_assignment_discussion_update();


      ALTER TABLE ONLY activity_log_grit_assignment_discussions
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_grit_assignment_discussions
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_grit_assignment_discussions
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (grit_assignment_id) REFERENCES grit_assignments(id);

      ALTER TABLE ONLY activity_log_grit_assignment_discussion_history
          ADD CONSTRAINT fk_activity_log_grit_assignment_discussion_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_grit_assignment_discussion_history
          ADD CONSTRAINT fk_activity_log_grit_assignment_discussion_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_grit_assignment_discussion_history
          ADD CONSTRAINT fk_activity_log_grit_assignment_discussion_history_grit_assignment_discussion_id FOREIGN KEY (grit_assignment_id) REFERENCES grit_assignments(id);

      ALTER TABLE ONLY activity_log_grit_assignment_discussion_history
          ADD CONSTRAINT fk_activity_log_grit_assignment_discussion_history_activity_log_grit_assignment_discussions FOREIGN KEY (activity_log_grit_assignment_discussion_id) REFERENCES activity_log_grit_assignment_discussions(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
