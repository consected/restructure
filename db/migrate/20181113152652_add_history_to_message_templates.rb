class AddHistoryToMessageTemplates < ActiveRecord::Migration
  def change
#
reversible do |dir|
  dir.up do

execute <<EOF

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create message_templates name template_type template

CREATE OR REPLACE FUNCTION log_message_template_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO message_template_history
            (
                name,
                template_type,
                template,
                admin_id,
                disabled,
                created_at,
                updated_at,
                message_template_id
                )
            SELECT
                NEW.name,
                NEW.template_type,
                NEW.template,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE message_template_history (
    id integer NOT NULL,
    name varchar,
    template_type varchar,
    template varchar,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    message_template_id integer
);

CREATE SEQUENCE message_template_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE message_template_history_id_seq OWNED BY message_template_history.id;


ALTER TABLE ONLY message_template_history ALTER COLUMN id SET DEFAULT nextval('message_template_history_id_seq'::regclass);

ALTER TABLE ONLY message_template_history
    ADD CONSTRAINT message_template_history_pkey PRIMARY KEY (id);

CREATE INDEX index_message_template_history_on_message_template_id ON message_template_history USING btree (message_template_id);
CREATE INDEX index_message_template_history_on_admin_id ON message_template_history USING btree (admin_id);

CREATE TRIGGER message_template_history_insert AFTER INSERT ON message_templates FOR EACH ROW EXECUTE PROCEDURE log_message_template_update();
CREATE TRIGGER message_template_history_update AFTER UPDATE ON message_templates FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_message_template_update();

ALTER TABLE ONLY message_template_history
    ADD CONSTRAINT fk_message_template_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY message_template_history
    ADD CONSTRAINT fk_message_template_history_message_templates FOREIGN KEY (message_template_id) REFERENCES message_templates(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;

EOF
end
dir.down do

execute <<EOF


DROP TABLE if exists message_template_history CASCADE;
DROP FUNCTION if exists log_message_template_update() CASCADE;

EOF

end
end

  end
end
