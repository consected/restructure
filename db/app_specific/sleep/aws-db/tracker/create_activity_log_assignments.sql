
      BEGIN;

      CREATE TABLE activity_log_sleep_assignment_history (
          id integer NOT NULL,
          master_id integer,
          sleep_assignment_id integer,
          select_activity varchar,
          activity_date date,
          select_record_from_player_contacts varchar,
          select_direction varchar,
          select_who varchar,
          select_result varchar,
          select_next_step varchar,
          follow_up_when date,
          follow_up_time time,
          notes varchar,
          protocol_id bigint,
          select_record_from_addresses varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_sleep_assignment_id integer
      );
      CREATE TABLE activity_log_sleep_assignments (
          id integer NOT NULL,
          master_id integer,
          sleep_assignment_id integer,
          select_activity varchar,
          activity_date date,
          select_record_from_player_contacts varchar,
          select_direction varchar,
          select_who varchar,
          select_result varchar,
          select_next_step varchar,
          follow_up_when date,
          follow_up_time time,
          notes varchar,
          protocol_id bigint,
          select_record_from_addresses varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE FUNCTION log_activity_log_sleep_assignment_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_sleep_assignment_history
                  (
                      master_id,
                      sleep_assignment_id,
                      select_activity,
                      activity_date,
                      select_record_from_player_contacts,
                      select_direction,
                      select_who,
                      select_result,
                      select_next_step,
                      follow_up_when,
                      follow_up_time,
                      notes,
                      protocol_id,
                      select_record_from_addresses,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_sleep_assignment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.sleep_assignment_id,
                      NEW.select_activity,
                      NEW.activity_date,
                      NEW.select_record_from_player_contacts,
                      NEW.select_direction,
                      NEW.select_who,
                      NEW.select_result,
                      NEW.select_next_step,
                      NEW.follow_up_when,
                      NEW.follow_up_time,
                      NEW.notes,
                      NEW.protocol_id,
                      NEW.select_record_from_addresses,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE SEQUENCE activity_log_sleep_assignment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_sleep_assignment_history_id_seq OWNED BY activity_log_sleep_assignment_history.id;


      CREATE SEQUENCE activity_log_sleep_assignments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_sleep_assignments_id_seq OWNED BY activity_log_sleep_assignments.id;

      ALTER TABLE ONLY activity_log_sleep_assignments ALTER COLUMN id SET DEFAULT nextval('activity_log_sleep_assignments_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_sleep_assignment_history ALTER COLUMN id SET DEFAULT nextval('activity_log_sleep_assignment_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_sleep_assignment_history
          ADD CONSTRAINT activity_log_sleep_assignment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_sleep_assignments
          ADD CONSTRAINT activity_log_sleep_assignments_pkey PRIMARY KEY (id);

      CREATE INDEX index_activity_log_sleep_assignment_history_on_master_id ON activity_log_sleep_assignment_history USING btree (master_id);
      CREATE INDEX index_activity_log_sleep_assignment_history_on_sleep_assignment_id ON activity_log_sleep_assignment_history USING btree (sleep_assignment_id);

      CREATE INDEX index_activity_log_sleep_assignment_history_on_activity_log_sleep_assignment_id ON activity_log_sleep_assignment_history USING btree (activity_log_sleep_assignment_id);
      CREATE INDEX index_activity_log_sleep_assignment_history_on_user_id ON activity_log_sleep_assignment_history USING btree (user_id);

      CREATE INDEX index_activity_log_sleep_assignments_on_master_id ON activity_log_sleep_assignments USING btree (master_id);
      CREATE INDEX index_activity_log_sleep_assignments_on_sleep_assignment_id ON activity_log_sleep_assignments USING btree (sleep_assignment_id);
      CREATE INDEX index_activity_log_sleep_assignments_on_user_id ON activity_log_sleep_assignments USING btree (user_id);

      CREATE TRIGGER activity_log_sleep_assignment_history_insert AFTER INSERT ON activity_log_sleep_assignments FOR EACH ROW EXECUTE PROCEDURE log_activity_log_sleep_assignment_update();
      CREATE TRIGGER activity_log_sleep_assignment_history_update AFTER UPDATE ON activity_log_sleep_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_sleep_assignment_update();


      ALTER TABLE ONLY activity_log_sleep_assignments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_sleep_assignments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_sleep_assignments
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (sleep_assignment_id) REFERENCES sleep_assignments(id);

      ALTER TABLE ONLY activity_log_sleep_assignment_history
          ADD CONSTRAINT fk_activity_log_sleep_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_sleep_assignment_history
          ADD CONSTRAINT fk_activity_log_sleep_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_sleep_assignment_history
          ADD CONSTRAINT fk_activity_log_sleep_assignment_history_sleep_assignment_id FOREIGN KEY (sleep_assignment_id) REFERENCES sleep_assignments(id);

      ALTER TABLE ONLY activity_log_sleep_assignment_history
          ADD CONSTRAINT fk_activity_log_sleep_assignment_history_activity_log_sleep_assignments FOREIGN KEY (activity_log_sleep_assignment_id) REFERENCES activity_log_sleep_assignments(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
