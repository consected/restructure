class CreateAthenaWebApp < ActiveRecord::Migration[5.2]
  include ActiveRecord::Migration::AppGenerator

  def change
    ActiveRecord::Base.connection.execute <<~END_SQL
      create schema IF NOT EXISTS athena_web_app authorization fphs;
      
      GRANT ALL ON SCHEMA athena_web_app TO fphs;
      GRANT USAGE ON SCHEMA athena_web_app TO fphsadm;
      GRANT USAGE ON SCHEMA athena_web_app TO fphsusr;
      GRANT USAGE ON SCHEMA athena_web_app TO fphsetl;
      GRANT USAGE ON SCHEMA athena_web_app TO fphsrailsapp;
      GRANT USAGE ON SCHEMA athena_web_app TO fphsbkp;
      
      
      CREATE TABLE athena_web_app.delayed_jobs (
          id integer NOT NULL,
          priority integer NOT NULL,
          attempts integer NOT NULL,
          handler text NOT NULL,
          last_error text,
          run_at timestamp without time zone,
          locked_at timestamp without time zone,
          failed_at timestamp without time zone,
          locked_by character varying,
          queue character varying,
          created_at timestamp without time zone,
          updated_at timestamp without time zone
      );
      

      CREATE SEQUENCE athena_web_app.delayed_jobs_id_seq;
      ALTER SEQUENCE athena_web_app.delayed_jobs_id_seq
      INCREMENT BY 1
      MINVALUE 1
      MAXVALUE 9223372036854775807
      START WITH 1
      NO CYCLE;


      ALTER SEQUENCE athena_web_app.delayed_jobs_id_seq OWNER TO fphs;

      GRANT SELECT ON athena_web_app.delayed_jobs_id_seq TO fphsusr;
      GRANT SELECT ON athena_web_app.delayed_jobs_id_seq TO fphsadm;
      GRANT SELECT ON athena_web_app.delayed_jobs_id_seq TO fphsetl;
      GRANT SELECT ON athena_web_app.delayed_jobs_id_seq TO fphsrailsapp;
      GRANT SELECT ON athena_web_app.delayed_jobs_id_seq TO fphsbkp;


      
      ALTER TABLE athena_web_app.delayed_jobs ALTER id SET DEFAULT nextval('athena_web_app.delayed_jobs_id_seq'::regclass);
      ALTER TABLE athena_web_app.delayed_jobs ALTER priority SET DEFAULT 0;
      ALTER TABLE athena_web_app.delayed_jobs ALTER attempts SET DEFAULT 0;
      
      ALTER TABLE athena_web_app.delayed_jobs ADD CONSTRAINT delayed_jobs_pkey
        PRIMARY KEY (id);
      
      CREATE INDEX delayed_jobs_priority ON athena_web_app.delayed_jobs USING btree (priority, run_at);
      
      ALTER TABLE athena_web_app.delayed_jobs OWNER TO fphs;
      
      GRANT DELETE ON athena_web_app.delayed_jobs TO fphsusr;
      GRANT INSERT ON athena_web_app.delayed_jobs TO fphsusr;
      GRANT SELECT ON athena_web_app.delayed_jobs TO fphsusr;
      GRANT UPDATE ON athena_web_app.delayed_jobs TO fphsusr;
      GRANT DELETE ON athena_web_app.delayed_jobs TO fphsadm;
      GRANT INSERT ON athena_web_app.delayed_jobs TO fphsadm;
      GRANT SELECT ON athena_web_app.delayed_jobs TO fphsadm;
      GRANT TRUNCATE ON athena_web_app.delayed_jobs TO fphsadm;
      GRANT UPDATE ON athena_web_app.delayed_jobs TO fphsadm;
      GRANT DELETE ON athena_web_app.delayed_jobs TO fphsetl;
      GRANT INSERT ON athena_web_app.delayed_jobs TO fphsetl;
      GRANT SELECT ON athena_web_app.delayed_jobs TO fphsetl;
      GRANT UPDATE ON athena_web_app.delayed_jobs TO fphsetl;
      GRANT DELETE ON athena_web_app.delayed_jobs TO fphsrailsapp;
      GRANT INSERT ON athena_web_app.delayed_jobs TO fphsrailsapp;
      GRANT SELECT ON athena_web_app.delayed_jobs TO fphsrailsapp;
      GRANT UPDATE ON athena_web_app.delayed_jobs TO fphsrailsapp;
      GRANT SELECT ON athena_web_app.delayed_jobs TO fphsbkp;
      
    END_SQL
  end
end
