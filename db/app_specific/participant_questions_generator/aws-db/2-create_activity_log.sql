SET SEARCH_PATH={{app_schema}},ml_app;

      BEGIN;

      CREATE TABLE activity_log_{{app_name}}_assignment_history (
          id integer NOT NULL,
          master_id integer,
          {{app_name}}_assignment_id integer,
          select_record_from_player_contact_phones varchar,
          return_call_availability_notes varchar,
          questions_from_call_notes varchar,
          results_link varchar,
          select_result varchar,
          pi_return_call_notes varchar,
          completed_q1_no_yes varchar,
          completed_teamstudy_no_yes varchar,
          previous_contact_with_team_no_yes varchar,
          previous_contact_with_team_notes varchar,
          notes varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          activity_log_{{app_name}}_assignment_id integer
      );
      CREATE TABLE activity_log_{{app_name}}_assignments (
          id integer NOT NULL,
          master_id integer,
          {{app_name}}_assignment_id integer,
          select_record_from_player_contact_phones varchar,
          return_call_availability_notes varchar,
          questions_from_call_notes varchar,
          results_link varchar,
          select_result varchar,
          pi_return_call_notes varchar,
          completed_q1_no_yes varchar,
          completed_teamstudy_no_yes varchar,
          previous_contact_with_team_no_yes varchar,
          previous_contact_with_team_notes varchar,
          notes varchar,
          extra_log_type varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );

      CREATE FUNCTION log_activity_log_{{app_name}}_assignment_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO activity_log_{{app_name}}_assignment_history
                  (
                      master_id,
                      {{app_name}}_assignment_id,
                      select_record_from_player_contact_phones,
                      return_call_availability_notes,
                      questions_from_call_notes,
                      results_link,
                      select_result,
                      pi_return_call_notes,
                      completed_q1_no_yes,
                      completed_teamstudy_no_yes,
                      previous_contact_with_team_no_yes,
                      previous_contact_with_team_notes,
                      notes,
                      extra_log_type,
                      user_id,
                      created_at,
                      updated_at,
                      activity_log_{{app_name}}_assignment_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.{{app_name}}_assignment_id,
                      NEW.select_record_from_player_contact_phones,
                      NEW.return_call_availability_notes,
                      NEW.questions_from_call_notes,
                      NEW.results_link,
                      NEW.select_result,
                      NEW.pi_return_call_notes,
                      NEW.completed_q1_no_yes,
                      NEW.completed_teamstudy_no_yes,
                      NEW.previous_contact_with_team_no_yes,
                      NEW.previous_contact_with_team_notes,
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

      CREATE SEQUENCE activity_log_{{app_name}}_assignment_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_{{app_name}}_assignment_history_id_seq OWNED BY activity_log_{{app_name}}_assignment_history.id;


      CREATE SEQUENCE activity_log_{{app_name}}_assignments_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE activity_log_{{app_name}}_assignments_id_seq OWNED BY activity_log_{{app_name}}_assignments.id;

      ALTER TABLE ONLY activity_log_{{app_name}}_assignments ALTER COLUMN id SET DEFAULT nextval('activity_log_{{app_name}}_assignments_id_seq'::regclass);
      ALTER TABLE ONLY activity_log_{{app_name}}_assignment_history ALTER COLUMN id SET DEFAULT nextval('activity_log_{{app_name}}_assignment_history_id_seq'::regclass);

      ALTER TABLE ONLY activity_log_{{app_name}}_assignment_history
          ADD CONSTRAINT activity_log_{{app_name}}_assignment_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY activity_log_{{app_name}}_assignments
          ADD CONSTRAINT activity_log_{{app_name}}_assignments_pkey PRIMARY KEY (id);

      CREATE INDEX index_activity_log_{{app_name}}_assignment_history_on_master_id ON activity_log_{{app_name}}_assignment_history USING btree (master_id);
      CREATE INDEX index_activity_log_{{app_name}}_assignment_history_on_{{app_name}}_assignment_id ON activity_log_{{app_name}}_assignment_history USING btree ({{app_name}}_assignment_id);

      CREATE INDEX index_activity_log_{{app_name}}_assignment_history_on_activity_log_{{app_name}}_assignment_id ON activity_log_{{app_name}}_assignment_history USING btree (activity_log_{{app_name}}_assignment_id);
      CREATE INDEX index_activity_log_{{app_name}}_assignment_history_on_user_id ON activity_log_{{app_name}}_assignment_history USING btree (user_id);

      CREATE INDEX index_activity_log_{{app_name}}_assignments_on_master_id ON activity_log_{{app_name}}_assignments USING btree (master_id);
      CREATE INDEX index_activity_log_{{app_name}}_assignments_on_{{app_name}}_assignment_id ON activity_log_{{app_name}}_assignments USING btree ({{app_name}}_assignment_id);
      CREATE INDEX index_activity_log_{{app_name}}_assignments_on_user_id ON activity_log_{{app_name}}_assignments USING btree (user_id);

      CREATE TRIGGER activity_log_{{app_name}}_assignment_history_insert AFTER INSERT ON activity_log_{{app_name}}_assignments FOR EACH ROW EXECUTE PROCEDURE log_activity_log_{{app_name}}_assignment_update();
      CREATE TRIGGER activity_log_{{app_name}}_assignment_history_update AFTER UPDATE ON activity_log_{{app_name}}_assignments FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_activity_log_{{app_name}}_assignment_update();


      ALTER TABLE ONLY activity_log_{{app_name}}_assignments
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY activity_log_{{app_name}}_assignments
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);
      ALTER TABLE ONLY activity_log_{{app_name}}_assignments
          ADD CONSTRAINT fk_rails_78888ed085 FOREIGN KEY ({{app_name}}_assignment_id) REFERENCES {{app_name}}_assignments(id);

      ALTER TABLE ONLY activity_log_{{app_name}}_assignment_history
          ADD CONSTRAINT fk_activity_log_{{app_name}}_assignment_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY activity_log_{{app_name}}_assignment_history
          ADD CONSTRAINT fk_activity_log_{{app_name}}_assignment_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);

      ALTER TABLE ONLY activity_log_{{app_name}}_assignment_history
          ADD CONSTRAINT fk_activity_log_{{app_name}}_assignment_history_{{app_name}}_assignment_id FOREIGN KEY ({{app_name}}_assignment_id) REFERENCES {{app_name}}_assignments(id);

      ALTER TABLE ONLY activity_log_{{app_name}}_assignment_history
          ADD CONSTRAINT fk_activity_log_{{app_name}}_assignment_history_activity_log_{{app_name}}_assignments FOREIGN KEY (activity_log_{{app_name}}_assignment_id) REFERENCES activity_log_{{app_name}}_assignments(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
