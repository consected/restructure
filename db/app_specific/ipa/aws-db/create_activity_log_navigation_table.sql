
      BEGIN;

-- Command line:
-- table_generators/generate.sh activity_logs_table create activity_log_ipa_assignment_navigations ipa_assignment event_date select_station arrival_time start_time event_notes completion_time participant_feedback_notes other_navigator_notes add_protocol_deviation_record_no_yes add_adverse_event_record_no_yes select_event_type other_event_type

      CREATE TABLE activity_log_ipa_assignment_navigation_history (
          id integer NOT NULL,
          master_id integer,
          ipa_assignment_id integer,
          event_date date,
          select_station varchar,
          select_navigator varchar,
          arrival_time time,
          start_time time,
          event_notes varchar,
          completion_time time,
          participant_feedback_notes varchar,
          other_navigator_notes varchar,
          add_protocol_deviation_record_no_yes varchar,
          add_adverse_event_record_no_yes varchar,
          select_event_type varchar,
          other_event_type varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_ipa_assignment_navigation_id integer
      );
      CREATE TABLE activity_log_ipa_assignment_navigations (
          id integer NOT NULL,
          master_id integer,
          ipa_assignment_id integer,
          event_date date,
          select_station varchar,
          select_navigator varchar,
          arrival_time time,
          start_time time,
          event_notes varchar,
          completion_time time,
          participant_feedback_notes varchar,
          other_navigator_notes varchar,
          add_protocol_deviation_record_no_yes varchar,
          add_adverse_event_record_no_yes varchar,
          select_event_type varchar,
          other_event_type varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE OR REPLACE FUNCTION log_activity_log_ipa_assignment_navigation_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_navigation_history
                  (
                      master_id,
                      ipa_assignment_id,
                      event_date,
                      select_station,
                      select_navigator,
                      arrival_time,
                      start_time,
                      event_notes,
                      completion_time,
                      participant_feedback_notes,
                      other_navigator_notes,
                      add_protocol_deviation_record_no_yes,
                      add_adverse_event_record_no_yes,
                      select_event_type,
                      other_event_type,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_navigation_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.event_date,
                      NEW.select_station,
                      NEW.select_navigator,
                      NEW.arrival_time,
                      NEW.start_time,
                      NEW.event_notes,
                      NEW.completion_time,
                      NEW.participant_feedback_notes,
                      NEW.other_navigator_notes,
                      NEW.add_protocol_deviation_record_no_yes,
                      NEW.add_adverse_event_record_no_yes,
                      NEW.select_event_type,
                      NEW.other_event_type,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE SEQUENCE activity_log_ipa_assignment_navigation_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_ipa_assignment_navigation_history_id_seq OWNED BY activity_log_ipa_assignment_navigation_history.id;


      CREATE SEQUENCE activity_log_ipa_assignment_navigations_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_ipa_assignment_navigations_id_seq OWNED BY activity_log_ipa_assignment_navigations.id;

      ALTER TABLE ONLY activity_log_ipa_assignment_navigations ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_assignment_navigations_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_ipa_assignment_navigation_history ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_assignment_navigation_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_ipa_assignment_navigation_history
          ADD CONSTRAINT activity_log_ipa_assignment_navigation_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_ipa_assignment_navigations
          ADD CONSTRAINT activity_log_ipa_assignment_navigations_pkey PRIMARY KEY (id);

      CREATE INDEX index_activity_log_ipa_assignment_navigation_history_on_master_id ON activity_log_ipa_assignment_navigation_history USING btree (master_id);
      CREATE INDEX index_activity_log_ipa_assignment_navigation_history_on_ipa_assignment_navigation_id ON activity_log_ipa_assignment_navigation_history USING btree (ipa_assignment_id);

      CREATE INDEX index_activity_log_ipa_assignment_navigation_history_on_activity_log_ipa_assignment_navigation_id ON activity_log_ipa_assignment_navigation_history USING btree (activity_log_ipa_assignment_navigation_id);
      CREATE INDEX index_activity_log_ipa_assignment_navigation_history_on_user_id ON activity_log_ipa_assignment_navigation_history USING btree (user_id);

      CREATE INDEX index_activity_log_ipa_assignment_navigations_on_master_id ON activity_log_ipa_assignment_navigations USING btree (master_id);
      CREATE INDEX index_activity_log_ipa_assignment_navigations_on_ipa_assignment_navigation_id ON activity_log_ipa_assignment_navigations USING btree (ipa_assignment_id);
      CREATE INDEX index_activity_log_ipa_assignment_navigations_on_user_id ON activity_log_ipa_assignment_navigations USING btree (user_id);

      CREATE TRIGGER activity_log_ipa_assignment_navigation_history_insert AFTER INSERT ON activity_log_ipa_assignment_navigations FOR EACH ROW EXECUTE PROCEDURE log_activity_log_ipa_assignment_navigation_update();
      CREATE TRIGGER activity_log_ipa_assignment_navigation_history_update AFTER UPDATE ON activity_log_ipa_assignment_navigations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_ipa_assignment_navigation_update();


      ALTER TABLE ONLY activity_log_ipa_assignment_navigations
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_ipa_assignment_navigations
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_ipa_assignment_navigations
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_assignments(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_navigation_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_navigation_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_navigation_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_navigation_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_navigation_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_navigation_history_ipa_assignment_navigation_id FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_assignments(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_navigation_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_navigation_history_activity_log_ipa_assignment_navigations FOREIGN KEY (activity_log_ipa_assignment_navigation_id) REFERENCES activity_log_ipa_assignment_navigations(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
