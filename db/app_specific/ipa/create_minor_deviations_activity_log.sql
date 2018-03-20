
      BEGIN;

-- Command line:
-- table_generators/generate.sh $@      

      CREATE TABLE activity_log_ipa_assignment_minor_deviation_history (
          id integer NOT NULL,
          master_id integer,
          ipa_assignment_id integer,
          activity_date date,
          deviation_discovered_when date,
          deviation_occurred_when date,
          deviation_description varchar,
          corrective_action_description varchar,
          select_status varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_ipa_assignment_minor_deviation_id integer
      );
      CREATE TABLE activity_log_ipa_assignment_minor_deviations (
          id integer NOT NULL,
          master_id integer,
          ipa_assignment_id integer,
          activity_date date,
          deviation_discovered_when date,
          deviation_occurred_when date,
          deviation_description varchar,
          corrective_action_description varchar,
          select_status varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE FUNCTION log_activity_log_ipa_assignment_minor_deviation_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_ipa_assignment_minor_deviation_history
                  (
                      master_id,
                      ipa_assignment_id,
                      activity_date,
                      deviation_discovered_when,
                      deviation_occurred_when,
                      deviation_description,
                      corrective_action_description,
                      select_status,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_ipa_assignment_minor_deviation_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.ipa_assignment_id,
                      NEW.activity_date,
                      NEW.deviation_discovered_when,
                      NEW.deviation_occurred_when,
                      NEW.deviation_description,
                      NEW.corrective_action_description,
                      NEW.select_status,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE SEQUENCE activity_log_ipa_assignment_minor_deviation_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_ipa_assignment_minor_deviation_history_id_seq OWNED BY activity_log_ipa_assignment_minor_deviation_history.id;


      CREATE SEQUENCE activity_log_ipa_assignment_minor_deviations_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_ipa_assignment_minor_deviations_id_seq OWNED BY activity_log_ipa_assignment_minor_deviations.id;

      ALTER TABLE ONLY activity_log_ipa_assignment_minor_deviations ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_assignment_minor_deviations_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_ipa_assignment_minor_deviation_history ALTER COLUMN id SET DEFAULT nextval('activity_log_ipa_assignment_minor_deviation_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_ipa_assignment_minor_deviation_history
          ADD CONSTRAINT activity_log_ipa_assignment_minor_deviation_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_ipa_assignment_minor_deviations
          ADD CONSTRAINT activity_log_ipa_assignment_minor_deviations_pkey PRIMARY KEY (id);

      CREATE INDEX index_activity_log_ipa_assignment_minor_deviation_history_on_master_id ON activity_log_ipa_assignment_minor_deviation_history USING btree (master_id);
      CREATE INDEX index_activity_log_ipa_assignment_minor_deviation_history_on_ipa_assignment_minor_deviation_id ON activity_log_ipa_assignment_minor_deviation_history USING btree (ipa_assignment_id);

      CREATE INDEX index_activity_log_ipa_assignment_minor_deviation_history_on_activity_log_ipa_assignment_minor_deviation_id ON activity_log_ipa_assignment_minor_deviation_history USING btree (activity_log_ipa_assignment_minor_deviation_id);
      CREATE INDEX index_activity_log_ipa_assignment_minor_deviation_history_on_user_id ON activity_log_ipa_assignment_minor_deviation_history USING btree (user_id);

      CREATE INDEX index_activity_log_ipa_assignment_minor_deviations_on_master_id ON activity_log_ipa_assignment_minor_deviations USING btree (master_id);
      CREATE INDEX index_activity_log_ipa_assignment_minor_deviations_on_ipa_assignment_minor_deviation_id ON activity_log_ipa_assignment_minor_deviations USING btree (ipa_assignment_id);
      CREATE INDEX index_activity_log_ipa_assignment_minor_deviations_on_user_id ON activity_log_ipa_assignment_minor_deviations USING btree (user_id);

      CREATE TRIGGER activity_log_ipa_assignment_minor_deviation_history_insert AFTER INSERT ON activity_log_ipa_assignment_minor_deviations FOR EACH ROW EXECUTE PROCEDURE log_activity_log_ipa_assignment_minor_deviation_update();
      CREATE TRIGGER activity_log_ipa_assignment_minor_deviation_history_update AFTER UPDATE ON activity_log_ipa_assignment_minor_deviations FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_ipa_assignment_minor_deviation_update();


      ALTER TABLE ONLY activity_log_ipa_assignment_minor_deviations
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_ipa_assignment_minor_deviations
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_ipa_assignment_minor_deviations
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_assignments(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_minor_deviation_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_minor_deviation_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_minor_deviation_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_minor_deviation_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_minor_deviation_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_minor_deviation_history_ipa_assignment_minor_deviation_id FOREIGN KEY (ipa_assignment_id) REFERENCES ipa_assignments(id);

      ALTER TABLE ONLY activity_log_ipa_assignment_minor_deviation_history
          ADD CONSTRAINT fk_activity_log_ipa_assignment_minor_deviation_history_activity_log_ipa_assignment_minor_deviations FOREIGN KEY (activity_log_ipa_assignment_minor_deviation_id) REFERENCES activity_log_ipa_assignment_minor_deviations(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
