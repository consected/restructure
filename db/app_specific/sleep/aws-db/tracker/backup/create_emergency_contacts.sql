BEGIN;

-- Command line:
-- table_generators/generate.sh dynamic_models_table create emergency_contacts rec_type data first_name last_name select_relationship rank

CREATE FUNCTION log_emergency_contact_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO emergency_contact_history
            (
                master_id,
                rec_type,
                data,
                first_name,
                last_name,
                select_relationship,
                rank,
                user_id,
                created_at,
                updated_at,
                emergency_contact_id
                )
            SELECT
                NEW.master_id,
                NEW.rec_type,
                NEW.data,
                NEW.first_name,
                NEW.last_name,
                NEW.select_relationship,
                NEW.rank,
                NEW.user_id,
                NEW.created_at,
                NEW.updated_at,
                NEW.id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TABLE emergency_contact_history (
    id integer NOT NULL,
    master_id integer,
    rec_type varchar,
    data varchar,
    first_name varchar,
    last_name varchar,
    select_relationship varchar,
    rank varchar,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    emergency_contact_id integer
);

CREATE SEQUENCE emergency_contact_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE emergency_contact_history_id_seq OWNED BY emergency_contact_history.id;

CREATE TABLE emergency_contacts (
    id integer NOT NULL,
    master_id integer,
    rec_type varchar,
    data varchar,
    first_name varchar,
    last_name varchar,
    select_relationship varchar,
    rank varchar,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);
CREATE SEQUENCE emergency_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER SEQUENCE emergency_contacts_id_seq OWNED BY emergency_contacts.id;

ALTER TABLE ONLY emergency_contacts ALTER COLUMN id SET DEFAULT nextval('emergency_contacts_id_seq'::regclass);
ALTER TABLE ONLY emergency_contact_history ALTER COLUMN id SET DEFAULT nextval('emergency_contact_history_id_seq'::regclass);

ALTER TABLE ONLY emergency_contact_history
    ADD CONSTRAINT emergency_contact_history_pkey PRIMARY KEY (id);

ALTER TABLE ONLY emergency_contacts
    ADD CONSTRAINT emergency_contacts_pkey PRIMARY KEY (id);

CREATE INDEX index_emergency_contact_history_on_master_id ON emergency_contact_history USING btree (master_id);


CREATE INDEX index_emergency_contact_history_on_emergency_contact_id ON emergency_contact_history USING btree (emergency_contact_id);
CREATE INDEX index_emergency_contact_history_on_user_id ON emergency_contact_history USING btree (user_id);

CREATE INDEX index_emergency_contacts_on_master_id ON emergency_contacts USING btree (master_id);

CREATE INDEX index_emergency_contacts_on_user_id ON emergency_contacts USING btree (user_id);

CREATE TRIGGER emergency_contact_history_insert AFTER INSERT ON emergency_contacts FOR EACH ROW EXECUTE PROCEDURE log_emergency_contact_update();
CREATE TRIGGER emergency_contact_history_update AFTER UPDATE ON emergency_contacts FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_emergency_contact_update();


ALTER TABLE ONLY emergency_contacts
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);
ALTER TABLE ONLY emergency_contacts
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);



ALTER TABLE ONLY emergency_contact_history
    ADD CONSTRAINT fk_emergency_contact_history_users FOREIGN KEY (user_id) REFERENCES users(id);

ALTER TABLE ONLY emergency_contact_history
    ADD CONSTRAINT fk_emergency_contact_history_masters FOREIGN KEY (master_id) REFERENCES masters(id);




ALTER TABLE ONLY emergency_contact_history
    ADD CONSTRAINT fk_emergency_contact_history_emergency_contacts FOREIGN KEY (emergency_contact_id) REFERENCES emergency_contacts(id);

GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA ml_app TO fphs;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA ml_app TO fphs;

COMMIT;
