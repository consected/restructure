
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create ${target_name_us}_ps_tmocas tmoca_score

      CREATE FUNCTION log_${target_name_us}_ps_tmoca_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ${target_name_us}_ps_tmoca_history
                  (
                      master_id,
                      tmoca_version,
                      attn_digit_span,
                      attn_digit_vigilance,
                      attn_digit_calculation,
                      language_repeat,
                      language_fluency,
                      abstraction,
                      delayed_recall,
                      orientation,
                      tmoca_score,
                      user_id,
                      created_at,
                      updated_at,
                      ${target_name_us}_ps_tmoca_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.tmoca_version,
                      NEW.attn_digit_span,
                      NEW.attn_digit_vigilance,
                      NEW.attn_digit_calculation,
                      NEW.language_repeat,
                      NEW.language_fluency,
                      NEW.abstraction,
                      NEW.delayed_recall,
                      NEW.orientation,
                      NEW.tmoca_score,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ${target_name_us}_ps_tmoca_history (
          id integer NOT NULL,
          master_id integer,
          tmoca_version varchar,
          attn_digit_span integer,
          attn_digit_vigilance integer,
          attn_digit_calculation integer,
          language_repeat integer,
          language_fluency integer,
          abstraction integer,
          delayed_recall integer,
          orientation integer,
          tmoca_score integer,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ${target_name_us}_ps_tmoca_id integer
      );

      CREATE SEQUENCE ${target_name_us}_ps_tmoca_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_ps_tmoca_history_id_seq OWNED BY ${target_name_us}_ps_tmoca_history.id;

      CREATE TABLE ${target_name_us}_ps_tmocas (
          id integer NOT NULL,
          master_id integer,
          tmoca_version varchar,
          attn_digit_span integer,
          attn_digit_vigilance integer,
          attn_digit_calculation integer,
          language_repeat integer,
          language_fluency integer,
          abstraction integer,
          delayed_recall integer,
          orientation integer,
          tmoca_score integer,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ${target_name_us}_ps_tmocas_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_ps_tmocas_id_seq OWNED BY ${target_name_us}_ps_tmocas.id;

      ALTER TABLE ONLY ${target_name_us}_ps_tmocas ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_ps_tmocas_id_seq'::regclass);
      ALTER TABLE ONLY ${target_name_us}_ps_tmoca_history ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_ps_tmoca_history_id_seq'::regclass);

      ALTER TABLE ONLY ${target_name_us}_ps_tmoca_history
          ADD CONSTRAINT ${target_name_us}_ps_tmoca_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ${target_name_us}_ps_tmocas
          ADD CONSTRAINT ${target_name_us}_ps_tmocas_pkey PRIMARY KEY (id);

      CREATE INDEX index_${target_name_us}_ps_tmoca_history_on_master_id ON ${target_name_us}_ps_tmoca_history USING btree (master_id);


      CREATE INDEX index_${target_name_us}_ps_tmoca_history_on_${target_name_us}_ps_tmoca_id ON ${target_name_us}_ps_tmoca_history USING btree (${target_name_us}_ps_tmoca_id);
      CREATE INDEX index_${target_name_us}_ps_tmoca_history_on_user_id ON ${target_name_us}_ps_tmoca_history USING btree (user_id);

      CREATE INDEX index_${target_name_us}_ps_tmocas_on_master_id ON ${target_name_us}_ps_tmocas USING btree (master_id);

      CREATE INDEX index_${target_name_us}_ps_tmocas_on_user_id ON ${target_name_us}_ps_tmocas USING btree (user_id);

      CREATE TRIGGER ${target_name_us}_ps_tmoca_history_insert AFTER INSERT ON ${target_name_us}_ps_tmocas FOR EACH ROW EXECUTE PROCEDURE log_${target_name_us}_ps_tmoca_update();
      CREATE TRIGGER ${target_name_us}_ps_tmoca_history_update AFTER UPDATE ON ${target_name_us}_ps_tmocas FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_${target_name_us}_ps_tmoca_update();


      ALTER TABLE ONLY ${target_name_us}_ps_tmocas
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ${target_name_us}_ps_tmocas
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ${target_name_us}_ps_tmoca_history
          ADD CONSTRAINT fk_${target_name_us}_ps_tmoca_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ${target_name_us}_ps_tmoca_history
          ADD CONSTRAINT fk_${target_name_us}_ps_tmoca_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ${target_name_us}_ps_tmoca_history
          ADD CONSTRAINT fk_${target_name_us}_ps_tmoca_history_${target_name_us}_ps_tmocas FOREIGN KEY (${target_name_us}_ps_tmoca_id) REFERENCES ${target_name_us}_ps_tmocas(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
