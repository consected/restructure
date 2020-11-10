class AddHistoryToPageLayouts < ActiveRecord::Migration
  def change
#
reversible do |dir|
  dir.up do

execute <<EOF

BEGIN;

-- Command line:
-- table_generators/generate.sh admin_history_table create page_layouts layout_name panel_name panel_label panel_position options

CREATE OR REPLACE FUNCTION log_page_layout_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO page_layout_history
            (
                layout_name,
                panel_name,
                panel_label,
                panel_position,
                options,
                admin_id,
                disabled,
                created_at,
                updated_at,
                page_layout_id
                )
            SELECT
                NEW.layout_name,
                NEW.panel_name,
                NEW.panel_label,
                NEW.panel_position,
                NEW.options,
                NEW.admin_id,
                NEW.disabled,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE page_layout_history (
    id integer NOT NULL,
    layout_name varchar,
    panel_name varchar,
    panel_label varchar,
    panel_position varchar,
    options varchar,
    admin_id integer,
    disabled boolean,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    page_layout_id integer
);

CREATE SEQUENCE page_layout_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE page_layout_history_id_seq OWNED BY page_layout_history.id;


ALTER TABLE ONLY page_layout_history ALTER COLUMN id SET DEFAULT nextval('page_layout_history_id_seq'::regclass);

ALTER TABLE ONLY page_layout_history
    ADD CONSTRAINT page_layout_history_pkey PRIMARY KEY (id);

CREATE INDEX index_page_layout_history_on_page_layout_id ON page_layout_history USING btree (page_layout_id);
CREATE INDEX index_page_layout_history_on_admin_id ON page_layout_history USING btree (admin_id);

CREATE TRIGGER page_layout_history_insert AFTER INSERT ON page_layouts FOR EACH ROW EXECUTE PROCEDURE log_page_layout_update();
CREATE TRIGGER page_layout_history_update AFTER UPDATE ON page_layouts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_page_layout_update();

ALTER TABLE ONLY page_layout_history
    ADD CONSTRAINT fk_page_layout_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

ALTER TABLE ONLY page_layout_history
    ADD CONSTRAINT fk_page_layout_history_page_layouts FOREIGN KEY (page_layout_id) REFERENCES page_layouts(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;

EOF
end
dir.down do

execute <<EOF


DROP TABLE if exists page_layout_history CASCADE;
DROP FUNCTION if exists log_page_layout_update() CASCADE;

EOF

end
end


    
  end
end
