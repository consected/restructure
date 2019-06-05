
      BEGIN;

-- Command line:
-- table_generators/generate.sh create dynamic_models_table ${target_name_us}_ps_sizes false weight height hat_size shirt_size jacket_size waist_size

      CREATE FUNCTION log_${target_name_us}_ps_size_update() RETURNS trigger
          LANGUAGE plpgsql
          AS $$
              BEGIN
                  INSERT INTO ${target_name_us}_ps_size_history
                  (
                      master_id,
                      birth_date,
                      weight,
                      height,
                      hat_size,
                      shirt_size,
                      jacket_size,
                      waist_size,
                      user_id,
                      created_at,
                      updated_at,
                      ${target_name_us}_ps_size_id
                      )
                  SELECT
                      NEW.master_id,
                      NEW.birth_date,
                      NEW.weight,
                      NEW.height,
                      NEW.hat_size,
                      NEW.shirt_size,
                      NEW.jacket_size,
                      NEW.waist_size,
                      NEW.user_id,
                      NEW.created_at,
                      NEW.updated_at,
                      NEW.id
                  ;
                  RETURN NEW;
              END;
          $$;

      CREATE TABLE ${target_name_us}_ps_size_history (
          id integer NOT NULL,
          master_id integer,
          birth_date date,
          weight integer,
          height varchar,
          hat_size varchar,
          shirt_size varchar,
          jacket_size varchar,
          waist_size varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL,
          ${target_name_us}_ps_size_id integer
      );

      CREATE SEQUENCE ${target_name_us}_ps_size_history_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_ps_size_history_id_seq OWNED BY ${target_name_us}_ps_size_history.id;

      CREATE TABLE ${target_name_us}_ps_sizes (
          id integer NOT NULL,
          master_id integer,
          birth_date date,
          weight integer,
          height varchar,
          hat_size varchar,
          shirt_size varchar,
          jacket_size varchar,
          waist_size varchar,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE ${target_name_us}_ps_sizes_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE ${target_name_us}_ps_sizes_id_seq OWNED BY ${target_name_us}_ps_sizes.id;

      ALTER TABLE ONLY ${target_name_us}_ps_sizes ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_ps_sizes_id_seq'::regclass);
      ALTER TABLE ONLY ${target_name_us}_ps_size_history ALTER COLUMN id SET DEFAULT nextval('${target_name_us}_ps_size_history_id_seq'::regclass);

      ALTER TABLE ONLY ${target_name_us}_ps_size_history
          ADD CONSTRAINT ${target_name_us}_ps_size_history_pkey PRIMARY KEY (id);

      ALTER TABLE ONLY ${target_name_us}_ps_sizes
          ADD CONSTRAINT ${target_name_us}_ps_sizes_pkey PRIMARY KEY (id);

      CREATE INDEX index_${target_name_us}_ps_size_history_on_master_id ON ${target_name_us}_ps_size_history USING btree (master_id);


      CREATE INDEX index_${target_name_us}_ps_size_history_on_${target_name_us}_ps_size_id ON ${target_name_us}_ps_size_history USING btree (${target_name_us}_ps_size_id);
      CREATE INDEX index_${target_name_us}_ps_size_history_on_user_id ON ${target_name_us}_ps_size_history USING btree (user_id);

      CREATE INDEX index_${target_name_us}_ps_sizes_on_master_id ON ${target_name_us}_ps_sizes USING btree (master_id);

      CREATE INDEX index_${target_name_us}_ps_sizes_on_user_id ON ${target_name_us}_ps_sizes USING btree (user_id);

      CREATE TRIGGER ${target_name_us}_ps_size_history_insert AFTER INSERT ON ${target_name_us}_ps_sizes FOR EACH ROW EXECUTE PROCEDURE log_${target_name_us}_ps_size_update();
      CREATE TRIGGER ${target_name_us}_ps_size_history_update AFTER UPDATE ON ${target_name_us}_ps_sizes FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_${target_name_us}_ps_size_update();


      ALTER TABLE ONLY ${target_name_us}_ps_sizes
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY ${target_name_us}_ps_sizes
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



      ALTER TABLE ONLY ${target_name_us}_ps_size_history
          ADD CONSTRAINT fk_${target_name_us}_ps_size_history_users FOREIGN KEY (user_id) REFERENCES users(id);

      ALTER TABLE ONLY ${target_name_us}_ps_size_history
          ADD CONSTRAINT fk_${target_name_us}_ps_size_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




      ALTER TABLE ONLY ${target_name_us}_ps_size_history
          ADD CONSTRAINT fk_${target_name_us}_ps_size_history_${target_name_us}_ps_sizes FOREIGN KEY (${target_name_us}_ps_size_id) REFERENCES ${target_name_us}_ps_sizes(id);

      GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
      GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

      COMMIT;
