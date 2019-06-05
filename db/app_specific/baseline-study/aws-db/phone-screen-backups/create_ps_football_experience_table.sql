
      BEGIN;

-- Command line:
-- table_generators/generate.sh create dynamic_models_table ${target_name_us}_ps_football_experiences false age played_in_nfl_blank_yes_no played_before_nfl_blank_yes_no football_experience_notes

      CREATE FUNCTION log_${target_name_us}_ps_football_experience_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ${target_name_us}_ps_football_experience_history
                  (
                      master_id,
                      age,
                      played_in_nfl_blank_yes_no,
--                      played_before_nfl_blank_yes_no,
--                      football_experience_notes,
                      user_id,
                      created_at,
                      updated_at,
                      ${target_name_us}_ps_football_experience_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.age,
                      NEW.played_in_nfl_blank_yes_no,
--                      NEW.played_before_nfl_blank_yes_no,
--                      NEW.football_experience_notes,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ${target_name_us}_ps_football_experience_history (
          id integer NOT NULL,
          master_id integer,
          age integer,
          played_in_nfl_blank_yes_no varchar,
--          played_before_nfl_blank_yes_no varchar,
--          football_experience_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ${target_name_us}_ps_football_experience_id integer
      );

      CREATE SEQUENCE ${target_name_us}_ps_football_experience_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_ps_football_experience_history_id_seq OWNED BY ${target_name_us}_ps_football_experience_history.id;

      CREATE TABLE ${target_name_us}_ps_football_experiences (
          id integer NOT NULL,
          master_id integer,
          age integer,
          played_in_nfl_blank_yes_no varchar,
--          played_before_nfl_blank_yes_no varchar,
--          football_experience_notes varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ${target_name_us}_ps_football_experiences_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_ps_football_experiences_id_seq OWNED BY ${target_name_us}_ps_football_experiences.id;

      ALTER TABLE ONLY ${target_name_us}_ps_football_experiences ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_ps_football_experiences_id_seq'::regclass);
      ALTER TABLE ONLY ${target_name_us}_ps_football_experience_history ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_ps_football_experience_history_id_seq'::regclass);

      ALTER TABLE ONLY ${target_name_us}_ps_football_experience_history
          ADD CONSTRAINT ${target_name_us}_ps_football_experience_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ${target_name_us}_ps_football_experiences
          ADD CONSTRAINT ${target_name_us}_ps_football_experiences_pkey PRIMARY KEY (id);

      CREATE INDEX index_${target_name_us}_ps_football_experience_history_on_master_id ON ${target_name_us}_ps_football_experience_history USING btree (master_id);


      CREATE INDEX index_${target_name_us}_ps_football_experience_history_on_${target_name_us}_ps_football_experience_id ON ${target_name_us}_ps_football_experience_history USING btree (${target_name_us}_ps_football_experience_id);
      CREATE INDEX index_${target_name_us}_ps_football_experience_history_on_user_id ON ${target_name_us}_ps_football_experience_history USING btree (user_id);

      CREATE INDEX index_${target_name_us}_ps_football_experiences_on_master_id ON ${target_name_us}_ps_football_experiences USING btree (master_id);

      CREATE INDEX index_${target_name_us}_ps_football_experiences_on_user_id ON ${target_name_us}_ps_football_experiences USING btree (user_id);

      CREATE TRIGGER ${target_name_us}_ps_football_experience_history_insert AFTER INSERT ON ${target_name_us}_ps_football_experiences FOR EACH ROW EXECUTE PROCEDURE log_${target_name_us}_ps_football_experience_update();
      CREATE TRIGGER ${target_name_us}_ps_football_experience_history_update AFTER UPDATE ON ${target_name_us}_ps_football_experiences FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_${target_name_us}_ps_football_experience_update();


      ALTER TABLE ONLY ${target_name_us}_ps_football_experiences
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ${target_name_us}_ps_football_experiences
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ${target_name_us}_ps_football_experience_history
          ADD CONSTRAINT fk_${target_name_us}_ps_football_experience_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ${target_name_us}_ps_football_experience_history
          ADD CONSTRAINT fk_${target_name_us}_ps_football_experience_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ${target_name_us}_ps_football_experience_history
          ADD CONSTRAINT fk_${target_name_us}_ps_football_experience_history_${target_name_us}_ps_football_experiences FOREIGN KEY (${target_name_us}_ps_football_experience_id) REFERENCES ${target_name_us}_ps_football_experiences(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
