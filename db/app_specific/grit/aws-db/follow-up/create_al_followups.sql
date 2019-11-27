set search_path=grit, ml_app;

      BEGIN;

-- Command line:
-- table_generators/generate.sh activity_logs_table create activity_log_grit_assignment_followups grit_assignment select_activity activity_date select_contact select_direction select_result select_next_step follow_up_when follow_up_time notes

      CREATE TABLE activity_log_grit_assignment_followup_history (
          id integer NOT NULL,
          master_id integer,
          grit_assignment_id integer,
          select_activity varchar,
          activity_date date,
          select_contact varchar,
          select_direction varchar,
          select_result varchar,
          select_next_step varchar,
          follow_up_when date,
          follow_up_time time,
          notes varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_grit_assignment_followup_id integer
      );
      CREATE TABLE activity_log_grit_assignment_followups (
          id integer NOT NULL,
          master_id integer,
          grit_assignment_id integer,
          select_activity varchar,
          activity_date date,
          select_contact varchar,
          select_direction varchar,
          select_result varchar,
          select_next_step varchar,
          follow_up_when date,
          follow_up_time time,
          notes varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE FUNCTION log_activity_log_grit_assignment_followup_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_grit_assignment_followup_history
                  (
                      master_id,
                      grit_assignment_id,
                      select_activity,
                      activity_date,
                      select_contact,
                      select_direction,
                      select_result,
                      select_next_step,
                      follow_up_when,
                      follow_up_time,
                      notes,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_grit_assignment_followup_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.grit_assignment_id,
                      NEW.select_activity,
                      NEW.activity_date,
                      NEW.select_contact,
                      NEW.select_direction,
                      NEW.select_result,
                      NEW.select_next_step,
                      NEW.follow_up_when,
                      NEW.follow_up_time,
                      NEW.notes,
                      NEW.extra_log_type,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE SEQUENCE activity_log_grit_assignment_followup_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_grit_assignment_followup_history_id_seq OWNED BY activity_log_grit_assignment_followup_history.id;


      CREATE SEQUENCE activity_log_grit_assignment_followups_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_grit_assignment_followups_id_seq OWNED BY activity_log_grit_assignment_followups.id;

      ALTER TABLE ONLY activity_log_grit_assignment_followups ALTER COLUMN id SET DEFAULT nextval('activity_log_grit_assignment_followups_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_grit_assignment_followup_history ALTER COLUMN id SET DEFAULT nextval('activity_log_grit_assignment_followup_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_grit_assignment_followup_history
          ADD CONSTRAINT activity_log_grit_assignment_followup_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_grit_assignment_followups
          ADD CONSTRAINT activity_log_grit_assignment_followups_pkey PRIMARY KEY (id);

      CREATE INDEX index_al_grit_assignment_followup_history_on_master_id ON activity_log_grit_assignment_followup_history USING btree (master_id);
      CREATE INDEX index_al_grit_assignment_followup_history_on_grit_assignment_followup_id ON activity_log_grit_assignment_followup_history USING btree (grit_assignment_id);

      CREATE INDEX index_al_grit_assignment_followup_history_on_activity_log_grit_assignment_followup_id ON activity_log_grit_assignment_followup_history USING btree (activity_log_grit_assignment_followup_id);
      CREATE INDEX index_al_grit_assignment_followup_history_on_user_id ON activity_log_grit_assignment_followup_history USING btree (user_id);

      CREATE INDEX index_activity_log_grit_assignment_followups_on_master_id ON activity_log_grit_assignment_followups USING btree (master_id);
      CREATE INDEX index_activity_log_grit_assignment_followups_on_grit_assignment_followup_id ON activity_log_grit_assignment_followups USING btree (grit_assignment_id);
      CREATE INDEX index_activity_log_grit_assignment_followups_on_user_id ON activity_log_grit_assignment_followups USING btree (user_id);

      CREATE TRIGGER activity_log_grit_assignment_followup_history_insert AFTER INSERT ON activity_log_grit_assignment_followups FOR EACH ROW EXECUTE PROCEDURE log_activity_log_grit_assignment_followup_update();
      CREATE TRIGGER activity_log_grit_assignment_followup_history_update AFTER UPDATE ON activity_log_grit_assignment_followups FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_grit_assignment_followup_update();


      ALTER TABLE ONLY activity_log_grit_assignment_followups
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_grit_assignment_followups
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_grit_assignment_followups
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY (grit_assignment_id) REFERENCES grit_assignments(id);

      ALTER TABLE ONLY activity_log_grit_assignment_followup_history
          ADD CONSTRAINT fk_activity_log_grit_assignment_followup_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_grit_assignment_followup_history
          ADD CONSTRAINT fk_activity_log_grit_assignment_followup_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_grit_assignment_followup_history
          ADD CONSTRAINT fk_activity_log_grit_assignment_followup_history_grit_assignment_followup_id FOREIGN KEY (grit_assignment_id) REFERENCES grit_assignments(id);

      ALTER TABLE ONLY activity_log_grit_assignment_followup_history
          ADD CONSTRAINT fk_activity_log_grit_assignment_followup_history_activity_log_grit_assignment_followups FOREIGN KEY (activity_log_grit_assignment_followup_id) REFERENCES activity_log_grit_assignment_followups(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
