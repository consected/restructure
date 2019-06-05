
      BEGIN;

-- Command line:
-- table_generators/generate.sh activity_logs_table create activity_log_${target_name_us}_assignment_adverse_events ${target_name_us}_assignment

      CREATE TABLE activity_log_${target_name_us}_assignment_adverse_event_history (
          id integer NOT NULL,
          master_id integer,
          ${target_name_us}_assignment_id integer,

          extra_log_type varchar,
          select_who varchar,
          done_when date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_${target_name_us}_assignment_adverse_event_id integer
      );
      CREATE TABLE activity_log_${target_name_us}_assignment_adverse_events (
          id integer NOT NULL,
          master_id integer,
          ${target_name_us}_assignment_id integer,

          extra_log_type varchar,
          select_who varchar,
          done_when date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE FUNCTION log_activity_log_${target_name_us}_assignment_adverse_event_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_${target_name_us}_assignment_adverse_event_history
                  (
                      master_id,
                      ${target_name_us}_assignment_id,

                      extra_log_type,
                      select_who,
                      done_when,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_${target_name_us}_assignment_adverse_event_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.${target_name_us}_assignment_id,

                      NEW.extra_log_type,
                      NEW.select_who,
                      NEW.done_when,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE SEQUENCE activity_log_${target_name_us}_assignment_adverse_event_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_${target_name_us}_assignment_adverse_event_history_id_seq OWNED BY activity_log_${target_name_us}_assignment_adverse_event_history.id;


      CREATE SEQUENCE activity_log_${target_name_us}_assignment_adverse_events_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_${target_name_us}_assignment_adverse_events_id_seq OWNED BY activity_log_${target_name_us}_assignment_adverse_events.id;

      ALTER TABLE ONLY activity_log_${target_name_us}_assignment_adverse_events ALTER COLUMN id SET DEFAULT nextval('activity_log_${target_name_us}_assignment_adverse_events_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_${target_name_us}_assignment_adverse_event_history ALTER COLUMN id SET DEFAULT nextval('activity_log_${target_name_us}_assignment_adverse_event_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_${target_name_us}_assignment_adverse_event_history
          ADD CONSTRAINT activity_log_${target_name_us}_assignment_adverse_event_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_${target_name_us}_assignment_adverse_events
          ADD CONSTRAINT activity_log_${target_name_us}_assignment_adverse_events_pkey PRIMARY KEY (id);

      CREATE INDEX index_al_${target_name_us}_assignment_adverse_event_history_on_master_id ON activity_log_${target_name_us}_assignment_adverse_event_history USING btree (master_id);
      CREATE INDEX index_al_${target_name_us}_assignment_adverse_event_history_on_${target_name_us}_assignment_adverse_event_id ON activity_log_${target_name_us}_assignment_adverse_event_history USING btree (${target_name_us}_assignment_id);

      CREATE INDEX index_al_${target_name_us}_assignment_adverse_event_history_on_activity_log_${target_name_us}_assignment_adverse_event_id ON activity_log_${target_name_us}_assignment_adverse_event_history USING btree (activity_log_${target_name_us}_assignment_adverse_event_id);
      CREATE INDEX index_al_${target_name_us}_assignment_adverse_event_history_on_user_id ON activity_log_${target_name_us}_assignment_adverse_event_history USING btree (user_id);

      CREATE INDEX index_activity_log_${target_name_us}_assignment_adverse_events_on_master_id ON activity_log_${target_name_us}_assignment_adverse_events USING btree (master_id);
      CREATE INDEX index_activity_log_${target_name_us}_assignment_adverse_events_on_${target_name_us}_assignment_adverse_event_id ON activity_log_${target_name_us}_assignment_adverse_events USING btree (${target_name_us}_assignment_id);
      CREATE INDEX index_activity_log_${target_name_us}_assignment_adverse_events_on_user_id ON activity_log_${target_name_us}_assignment_adverse_events USING btree (user_id);

      CREATE TRIGGER activity_log_${target_name_us}_assignment_adverse_event_history_insert AFTER INSERT ON activity_log_${target_name_us}_assignment_adverse_events FOR EACH ROW EXECUTE PROCEDURE log_activity_log_${target_name_us}_assignment_adverse_event_update();
      CREATE TRIGGER activity_log_${target_name_us}_assignment_adverse_event_history_update AFTER UPDATE ON activity_log_${target_name_us}_assignment_adverse_events FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_${target_name_us}_assignment_adverse_event_update();


      ALTER TABLE ONLY activity_log_${target_name_us}_assignment_adverse_events
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_${target_name_us}_assignment_adverse_events
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_${target_name_us}_assignment_adverse_events
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (${target_name_us}_assignment_id) REFERENCES ${target_name_us}_assignments(id);

      ALTER TABLE ONLY activity_log_${target_name_us}_assignment_adverse_event_history
          ADD CONSTRAINT fk_activity_log_${target_name_us}_assignment_adverse_event_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_${target_name_us}_assignment_adverse_event_history
          ADD CONSTRAINT fk_activity_log_${target_name_us}_assignment_adverse_event_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_${target_name_us}_assignment_adverse_event_history
          ADD CONSTRAINT fk_activity_log_${target_name_us}_assignment_adverse_event_history_${target_name_us}_assignment_adverse_event_id FOREIGN KEY (${target_name_us}_assignment_id) REFERENCES ${target_name_us}_assignments(id);

      ALTER TABLE ONLY activity_log_${target_name_us}_assignment_adverse_event_history
          ADD CONSTRAINT fk_activity_log_${target_name_us}_assignment_adverse_event_history_activity_log_${target_name_us}_assignment_adverse_events FOREIGN KEY (activity_log_${target_name_us}_assignment_adverse_event_id) REFERENCES activity_log_${target_name_us}_assignment_adverse_events(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
