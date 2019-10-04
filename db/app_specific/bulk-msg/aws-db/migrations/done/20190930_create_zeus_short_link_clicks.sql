set search_path=bulk_msg,ml_app;
      BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create zeus_short_link_clicks shortcode domain browser logfile action_timestamp

-- NO HISTORY

      CREATE TABLE zeus_short_link_clicks (
          id integer NOT NULL,
          master_id integer,
          shortcode varchar,
          domain varchar,
          browser varchar,
          logfile varchar,
          action_timestamp timestamp without time zone NOT NULL,
          user_id integer,
          created_at timestamp without time zone NOT NULL,
          updated_at timestamp without time zone NOT NULL
      );
      CREATE SEQUENCE zeus_short_link_clicks_id_seq
          START WITH 1
          INCREMENT BY 1
          NO MINVALUE
          NO MAXVALUE
          CACHE 1;

      ALTER SEQUENCE zeus_short_link_clicks_id_seq OWNED BY zeus_short_link_clicks.id;

      ALTER TABLE ONLY zeus_short_link_clicks ALTER COLUMN id SET DEFAULT nextval('zeus_short_link_clicks_id_seq'::regclass);

      ALTER TABLE ONLY zeus_short_link_clicks
          ADD CONSTRAINT zeus_short_link_clicks_pkey PRIMARY KEY (id);


      CREATE INDEX index_zeus_short_link_clicks_on_master_id ON zeus_short_link_clicks USING btree (master_id);

      CREATE INDEX index_zeus_short_link_clicks_on_user_id ON zeus_short_link_clicks USING btree (user_id);


      ALTER TABLE ONLY zeus_short_link_clicks
          ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
      ALTER TABLE ONLY zeus_short_link_clicks
          ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


      COMMIT;
