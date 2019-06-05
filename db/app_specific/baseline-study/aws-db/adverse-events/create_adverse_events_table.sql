
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ${target_name_us}_adverse_events event_occurred_when event_discovered_when select_severity select_location select_expectedness select_relatedness event_description corrective_action_description

      CREATE FUNCTION log_${target_name_us}_adverse_event_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ${target_name_us}_adverse_event_history
                  (
                      master_id,
                      select_problem_type,
                      event_occurred_when,
                      event_discovered_when,
                      select_severity,
                      select_location,
                      select_expectedness,
                      select_relatedness,
                      event_description,
                      corrective_action_description,
                      user_id,
                      created_at,
                      updated_at,
                      ${target_name_us}_adverse_event_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_problem_type,
                      NEW.event_occurred_when,
                      NEW.event_discovered_when,
                      NEW.select_severity,
                      NEW.select_location,
                      NEW.select_expectedness,
                      NEW.select_relatedness,
                      NEW.event_description,
                      NEW.corrective_action_description,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ${target_name_us}_adverse_event_history (
          id integer NOT NULL,
          master_id integer,
          select_problem_type varchar,
          event_occurred_when date,
          event_discovered_when date,
          select_severity varchar,
          select_location varchar,
          select_expectedness varchar,
          select_relatedness varchar,
          event_description varchar,
          corrective_action_description varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ${target_name_us}_adverse_event_id integer
      );

      CREATE SEQUENCE ${target_name_us}_adverse_event_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_adverse_event_history_id_seq OWNED BY ${target_name_us}_adverse_event_history.id;

      CREATE TABLE ${target_name_us}_adverse_events (
          id integer NOT NULL,
          master_id integer,
          select_problem_type varchar,
          event_occurred_when date,
          event_discovered_when date,
          select_severity varchar,
          select_location varchar,
          select_expectedness varchar,
          select_relatedness varchar,
          event_description varchar,
          corrective_action_description varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ${target_name_us}_adverse_events_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_adverse_events_id_seq OWNED BY ${target_name_us}_adverse_events.id;

      ALTER TABLE ONLY ${target_name_us}_adverse_events ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_adverse_events_id_seq'::regclass);
      ALTER TABLE ONLY ${target_name_us}_adverse_event_history ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_adverse_event_history_id_seq'::regclass);

      ALTER TABLE ONLY ${target_name_us}_adverse_event_history
          ADD CONSTRAINT ${target_name_us}_adverse_event_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ${target_name_us}_adverse_events
          ADD CONSTRAINT ${target_name_us}_adverse_events_pkey PRIMARY KEY (id);

      CREATE INDEX index_${target_name_us}_adverse_event_history_on_master_id ON ${target_name_us}_adverse_event_history USING btree (master_id);


      CREATE INDEX index_${target_name_us}_adverse_event_history_on_${target_name_us}_adverse_event_id ON ${target_name_us}_adverse_event_history USING btree (${target_name_us}_adverse_event_id);
      CREATE INDEX index_${target_name_us}_adverse_event_history_on_user_id ON ${target_name_us}_adverse_event_history USING btree (user_id);

      CREATE INDEX index_${target_name_us}_adverse_events_on_master_id ON ${target_name_us}_adverse_events USING btree (master_id);

      CREATE INDEX index_${target_name_us}_adverse_events_on_user_id ON ${target_name_us}_adverse_events USING btree (user_id);

      CREATE TRIGGER ${target_name_us}_adverse_event_history_insert AFTER INSERT ON ${target_name_us}_adverse_events FOR EACH ROW EXECUTE PROCEDURE log_${target_name_us}_adverse_event_update();
      CREATE TRIGGER ${target_name_us}_adverse_event_history_update AFTER UPDATE ON ${target_name_us}_adverse_events FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_${target_name_us}_adverse_event_update();


      ALTER TABLE ONLY ${target_name_us}_adverse_events
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ${target_name_us}_adverse_events
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ${target_name_us}_adverse_event_history
          ADD CONSTRAINT fk_${target_name_us}_adverse_event_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ${target_name_us}_adverse_event_history
          ADD CONSTRAINT fk_${target_name_us}_adverse_event_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ${target_name_us}_adverse_event_history
          ADD CONSTRAINT fk_${target_name_us}_adverse_event_history_${target_name_us}_adverse_events FOREIGN KEY (${target_name_us}_adverse_event_id) REFERENCES ${target_name_us}_adverse_events(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
