
      BEGIN;

      CREATE FUNCTION log_${target_name_us}_survey_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ${target_name_us}_survey_history
                  (
                      master_id,
                      select_survey_type,
                      sent_date,
                      completed_date,
                      send_next_survey_when,
                      notes,
                      user_id,
                      created_at,
                      updated_at,
                      ${target_name_us}_survey_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.select_survey_type,
                      NEW.sent_date,
                      NEW.completed_date,
                      NEW.send_next_survey_when,
                      NEW.notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ${target_name_us}_survey_history (
          id integer NOT NULL,
          master_id integer,
          select_survey_type varchar,
          sent_date date,
          completed_date date,
          send_next_survey_when date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ${target_name_us}_survey_id integer
      );

      CREATE SEQUENCE ${target_name_us}_survey_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_survey_history_id_seq OWNED BY ${target_name_us}_survey_history.id;

      CREATE TABLE ${target_name_us}_surveys (
          id integer NOT NULL,
          master_id integer,
          select_survey_type varchar,
          sent_date date,
          completed_date date,
          send_next_survey_when date,
          notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ${target_name_us}_surveys_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_surveys_id_seq OWNED BY ${target_name_us}_surveys.id;

      ALTER TABLE ONLY ${target_name_us}_surveys ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_surveys_id_seq'::regclass);
      ALTER TABLE ONLY ${target_name_us}_survey_history ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_survey_history_id_seq'::regclass);

      ALTER TABLE ONLY ${target_name_us}_survey_history
          ADD CONSTRAINT ${target_name_us}_survey_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ${target_name_us}_surveys
          ADD CONSTRAINT ${target_name_us}_surveys_pkey PRIMARY KEY (id);

      CREATE INDEX index_${target_name_us}_survey_history_on_master_id ON ${target_name_us}_survey_history USING btree (master_id);


      CREATE INDEX index_${target_name_us}_survey_history_on_${target_name_us}_survey_id ON ${target_name_us}_survey_history USING btree (${target_name_us}_survey_id);
      CREATE INDEX index_${target_name_us}_survey_history_on_user_id ON ${target_name_us}_survey_history USING btree (user_id);

      CREATE INDEX index_${target_name_us}_surveys_on_master_id ON ${target_name_us}_surveys USING btree (master_id);

      CREATE INDEX index_${target_name_us}_surveys_on_user_id ON ${target_name_us}_surveys USING btree (user_id);

      CREATE TRIGGER ${target_name_us}_survey_history_insert AFTER INSERT ON ${target_name_us}_surveys FOR EACH ROW EXECUTE PROCEDURE log_${target_name_us}_survey_update();
      CREATE TRIGGER ${target_name_us}_survey_history_update AFTER UPDATE ON ${target_name_us}_surveys FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_${target_name_us}_survey_update();


      ALTER TABLE ONLY ${target_name_us}_surveys
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ${target_name_us}_surveys
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ${target_name_us}_survey_history
          ADD CONSTRAINT fk_${target_name_us}_survey_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ${target_name_us}_survey_history
          ADD CONSTRAINT fk_${target_name_us}_survey_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ${target_name_us}_survey_history
          ADD CONSTRAINT fk_${target_name_us}_survey_history_${target_name_us}_surveys FOREIGN KEY (${target_name_us}_survey_id) REFERENCES ${target_name_us}_surveys(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
