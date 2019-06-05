
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ${target_name_us}_screenings eligible_for_study_blank_yes_no requires_study_partner_blank_yes_no notes good_time_to_speak_blank_yes_no callback_date callback_time still_interested_blank_yes_no not_interested_notes ineligible_notes eligible_notes

      CREATE or REPLACE FUNCTION log_${target_name_us}_screening_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ${target_name_us}_screening_history
                  (
                      master_id,
                      eligible_for_study_blank_yes_no,
                      requires_study_partner_blank_yes_no,
                      notes,
                      good_time_to_speak_blank_yes_no,
                      callback_date,
                      callback_time,
                      still_interested_blank_yes_no,
                      not_interested_notes,
                      ineligible_notes,
                      eligible_notes,
                      contact_in_future_yes_no,
                      user_id,
                      created_at,
                      updated_at,
                      ${target_name_us}_screening_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.eligible_for_study_blank_yes_no,
                      NEW.requires_study_partner_blank_yes_no,
                      NEW.notes,
                      NEW.good_time_to_speak_blank_yes_no,
                      NEW.callback_date,
                      NEW.callback_time,
                      NEW.still_interested_blank_yes_no,
                      NEW.not_interested_notes,
                      NEW.ineligible_notes,
                      NEW.eligible_notes,
                      NEW.contact_in_future_yes_no,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ${target_name_us}_screening_history (
          id integer NOT NULL,
          master_id integer,
          eligible_for_study_blank_yes_no varchar,
          requires_study_partner_blank_yes_no varchar,
          notes varchar,
          good_time_to_speak_blank_yes_no varchar,
          callback_date date,
          callback_time varchar,
          still_interested_blank_yes_no varchar,
          not_interested_notes varchar,
          contact_in_future_yes_no varchar,
          ineligible_notes varchar,
          eligible_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ${target_name_us}_screening_id integer
      );

      CREATE SEQUENCE ${target_name_us}_screening_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_screening_history_id_seq OWNED BY ${target_name_us}_screening_history.id;

      CREATE TABLE ${target_name_us}_screenings (
          id integer NOT NULL,
          master_id integer,
          eligible_for_study_blank_yes_no varchar,
          requires_study_partner_blank_yes_no varchar,
          notes varchar,
          good_time_to_speak_blank_yes_no varchar,
          callback_date date,
          callback_time varchar,
          still_interested_blank_yes_no varchar,
          not_interested_notes varchar,
          contact_in_future_yes_no varchar,
          ineligible_notes varchar,
          eligible_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ${target_name_us}_screenings_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_screenings_id_seq OWNED BY ${target_name_us}_screenings.id;

      ALTER TABLE ONLY ${target_name_us}_screenings ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_screenings_id_seq'::regclass);
      ALTER TABLE ONLY ${target_name_us}_screening_history ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_screening_history_id_seq'::regclass);

      ALTER TABLE ONLY ${target_name_us}_screening_history
          ADD CONSTRAINT ${target_name_us}_screening_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ${target_name_us}_screenings
          ADD CONSTRAINT ${target_name_us}_screenings_pkey PRIMARY KEY (id);

      CREATE INDEX index_${target_name_us}_screening_history_on_master_id ON ${target_name_us}_screening_history USING btree (master_id);


      CREATE INDEX index_${target_name_us}_screening_history_on_${target_name_us}_screening_id ON ${target_name_us}_screening_history USING btree (${target_name_us}_screening_id);
      CREATE INDEX index_${target_name_us}_screening_history_on_user_id ON ${target_name_us}_screening_history USING btree (user_id);

      CREATE INDEX index_${target_name_us}_screenings_on_master_id ON ${target_name_us}_screenings USING btree (master_id);

      CREATE INDEX index_${target_name_us}_screenings_on_user_id ON ${target_name_us}_screenings USING btree (user_id);

      CREATE TRIGGER ${target_name_us}_screening_history_insert AFTER INSERT ON ${target_name_us}_screenings FOR EACH ROW EXECUTE PROCEDURE log_${target_name_us}_screening_update();
      CREATE TRIGGER ${target_name_us}_screening_history_update AFTER UPDATE ON ${target_name_us}_screenings FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_${target_name_us}_screening_update();


      ALTER TABLE ONLY ${target_name_us}_screenings
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ${target_name_us}_screenings
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ${target_name_us}_screening_history
          ADD CONSTRAINT fk_${target_name_us}_screening_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ${target_name_us}_screening_history
          ADD CONSTRAINT fk_${target_name_us}_screening_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ${target_name_us}_screening_history
          ADD CONSTRAINT fk_${target_name_us}_screening_history_${target_name_us}_screenings FOREIGN KEY (${target_name_us}_screening_id) REFERENCES ${target_name_us}_screenings(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
