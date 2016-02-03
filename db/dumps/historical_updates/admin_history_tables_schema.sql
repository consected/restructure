set search_path=ml_app;

/****** ADMIN: general_selections HISTORY ******/
CREATE TABLE general_selection_history (
    id integer NOT NULL,
    name character varying,
    value character varying,
    item_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    create_with boolean,
    edit_if_set boolean,
    edit_always boolean,
    "position" integer,
    description character varying,
    lock boolean,
    general_selection_id integer
);

CREATE SEQUENCE general_selection_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE general_selection_history_id_seq OWNED BY general_selection_history.id;
ALTER TABLE ONLY general_selection_history ALTER COLUMN id SET DEFAULT nextval('general_selection_history_id_seq'::regclass);
ALTER TABLE ONLY general_selection_history ADD CONSTRAINT general_selection_history_pkey PRIMARY KEY (id);

CREATE INDEX index_general_selection_history_on_general_selection_id ON general_selection_history USING btree (general_selection_id);

ALTER TABLE ONLY general_selection_history ADD CONSTRAINT fk_general_selection_history_general_selections FOREIGN KEY (general_selection_id) REFERENCES general_selections(id);

CREATE FUNCTION log_general_selection_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO general_selection_history
            (
                    general_selection_id,
                    name ,
                    value ,
                    item_type ,
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id ,
                    create_with ,
                    edit_if_set ,
                    edit_always ,
                    position ,
                    description ,
                    lock 
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                NEW.value ,
                NEW.item_type ,
                NEW.created_at ,
                NEW.updated_at ,
                NEW.disabled ,
                NEW.admin_id ,
                NEW.create_with ,
                NEW.edit_if_set ,
                NEW.edit_always ,
                NEW.position "position",
                NEW.description ,
                NEW.lock
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER general_selection_history_insert AFTER INSERT ON general_selections FOR EACH ROW EXECUTE PROCEDURE log_general_selection_update();
CREATE TRIGGER general_selection_history_update AFTER UPDATE ON general_selections FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_general_selection_update();


/****** ADMIN: accuracy_scores HISTORY ******/
CREATE TABLE accuracy_score_history (
    id integer NOT NULL,
    name character varying,
    value integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    accuracy_score_id integer
);

CREATE SEQUENCE accuracy_score_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE accuracy_score_history_id_seq OWNED BY accuracy_score_history.id;
ALTER TABLE ONLY accuracy_score_history ALTER COLUMN id SET DEFAULT nextval('accuracy_score_history_id_seq'::regclass);
ALTER TABLE ONLY accuracy_score_history ADD CONSTRAINT accuracy_score_history_pkey PRIMARY KEY (id);

CREATE INDEX index_accuracy_score_history_on_accuracy_score_id ON accuracy_score_history USING btree (accuracy_score_id);

ALTER TABLE ONLY accuracy_score_history ADD CONSTRAINT fk_accuracy_score_history_accuracy_scores FOREIGN KEY (accuracy_score_id) REFERENCES accuracy_scores(id);

CREATE FUNCTION log_accuracy_score_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO accuracy_score_history
            (
                    accuracy_score_id,
                    name ,
                    value ,                    
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id                      
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                    NEW.value ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled ,
                    NEW.admin_id                      
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER accuracy_score_history_insert AFTER INSERT ON accuracy_scores FOR EACH ROW EXECUTE PROCEDURE log_accuracy_score_update();
CREATE TRIGGER accuracy_score_history_update AFTER UPDATE ON accuracy_scores FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_accuracy_score_update();



/****** ADMIN: colleges HISTORY ******/
CREATE TABLE college_history (
    id integer NOT NULL,
    name character varying,
    synonym_for_id integer,
    disabled boolean,
    admin_id integer,
    user_id integer,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    college_id integer
);

CREATE SEQUENCE college_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE college_history_id_seq OWNED BY college_history.id;
ALTER TABLE ONLY college_history ALTER COLUMN id SET DEFAULT nextval('college_history_id_seq'::regclass);
ALTER TABLE ONLY college_history ADD CONSTRAINT college_history_pkey PRIMARY KEY (id);

CREATE INDEX index_college_history_on_college_id ON college_history USING btree (college_id);

ALTER TABLE ONLY college_history ADD CONSTRAINT fk_college_history_colleges FOREIGN KEY (college_id) REFERENCES colleges(id);

CREATE FUNCTION log_college_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO college_history
            (
                    college_id,
                    name ,
                    synonym_for_id,
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id,
                    user_id            
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                    NEW.synonym_for_id ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled ,
                    NEW.admin_id,
                    NEW.user_id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER college_history_insert AFTER INSERT ON colleges FOR EACH ROW EXECUTE PROCEDURE log_college_update();
CREATE TRIGGER college_history_update AFTER UPDATE ON colleges FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_college_update();


/****** ADMIN: item_flag_names HISTORY ******/
CREATE TABLE item_flag_name_history (
    id integer NOT NULL,
    name character varying,
    item_type character varying,
    disabled boolean,
    admin_id integer,    
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    item_flag_name_id integer
);

CREATE SEQUENCE item_flag_name_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE item_flag_name_history_id_seq OWNED BY item_flag_name_history.id;
ALTER TABLE ONLY item_flag_name_history ALTER COLUMN id SET DEFAULT nextval('item_flag_name_history_id_seq'::regclass);
ALTER TABLE ONLY item_flag_name_history ADD CONSTRAINT item_flag_name_history_pkey PRIMARY KEY (id);

CREATE INDEX index_item_flag_name_history_on_item_flag_name_id ON item_flag_name_history USING btree (item_flag_name_id);

ALTER TABLE ONLY item_flag_name_history ADD CONSTRAINT fk_item_flag_name_history_item_flag_names FOREIGN KEY (item_flag_name_id) REFERENCES item_flag_names(id);

CREATE FUNCTION log_item_flag_name_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO item_flag_name_history
            (
                    item_flag_name_id,
                    name ,
                    item_type,
                    created_at ,
                    updated_at ,
                    disabled ,
                    admin_id
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,
                    NEW.item_type ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled ,
                    NEW.admin_id
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER item_flag_name_history_insert AFTER INSERT ON item_flag_names FOR EACH ROW EXECUTE PROCEDURE log_item_flag_name_update();
CREATE TRIGGER item_flag_name_history_update AFTER UPDATE ON item_flag_names FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_item_flag_name_update();


/****** ADMIN: item_flags HISTORY ******/
CREATE TABLE item_flag_history (
    id integer NOT NULL,
    item_id integer,
    item_type character varying,
    item_flag_name_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer,
    item_flag_id integer
);

CREATE SEQUENCE item_flag_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE item_flag_history_id_seq OWNED BY item_flag_history.id;
ALTER TABLE ONLY item_flag_history ALTER COLUMN id SET DEFAULT nextval('item_flag_history_id_seq'::regclass);
ALTER TABLE ONLY item_flag_history ADD CONSTRAINT item_flag_history_pkey PRIMARY KEY (id);

CREATE INDEX index_item_flag_history_on_item_flag_id ON item_flag_history USING btree (item_flag_id);

ALTER TABLE ONLY item_flag_history ADD CONSTRAINT fk_item_flag_history_item_flags FOREIGN KEY (item_flag_id) REFERENCES item_flags(id);

CREATE FUNCTION log_item_flag_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO item_flag_history
            (
                    item_flag_id,
                    item_id ,
                    item_type,
                    item_flag_name_id,
                    created_at ,
                    updated_at ,
                    user_id 
                )                 
            SELECT                 
                NEW.id,
                NEW.item_id ,
                    NEW.item_type,
                    NEW.item_flag_name_id,
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.user_id 
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER item_flag_history_insert AFTER INSERT ON item_flags FOR EACH ROW EXECUTE PROCEDURE log_item_flag_update();
CREATE TRIGGER item_flag_history_update AFTER UPDATE ON item_flags FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_item_flag_update();


/****** ADMIN: users HISTORY ******/
CREATE TABLE user_history (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying,
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0 NOT NULL,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip inet,
    last_sign_in_ip inet,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    failed_attempts integer DEFAULT 0 NOT NULL,
    unlock_token character varying,
    locked_at timestamp without time zone,
    disabled boolean,
    admin_id integer,

    user_id integer
);

CREATE SEQUENCE user_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE user_history_id_seq OWNED BY user_history.id;
ALTER TABLE ONLY user_history ALTER COLUMN id SET DEFAULT nextval('user_history_id_seq'::regclass);
ALTER TABLE ONLY user_history ADD CONSTRAINT user_history_pkey PRIMARY KEY (id);

CREATE INDEX index_user_history_on_user_id ON user_history USING btree (user_id);

ALTER TABLE ONLY user_history ADD CONSTRAINT fk_user_history_users FOREIGN KEY (user_id) REFERENCES users(id);

CREATE FUNCTION log_user_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO user_history
            (
                    user_id,
    email,
    encrypted_password,
    reset_password_token,
    reset_password_sent_at,
    remember_created_at,
    sign_in_count,
    current_sign_in_at,
    last_sign_in_at,
    current_sign_in_ip ,
    last_sign_in_ip ,
    created_at ,
    updated_at,
    failed_attempts,
    unlock_token,
    locked_at,
    disabled ,
    admin_id 

                )                 
            SELECT                 
                NEW.id,
                NEW.email,
    NEW.encrypted_password,
    NEW.reset_password_token,
    NEW.reset_password_sent_at,
    NEW.remember_created_at,
    NEW.sign_in_count,
    NEW.current_sign_in_at,
    NEW.last_sign_in_at,
    NEW.current_sign_in_ip ,
    NEW.last_sign_in_ip ,
    NEW.created_at ,
    NEW.updated_at,
    NEW.failed_attempts,
    NEW.unlock_token,
    NEW.locked_at,
    NEW.disabled ,
    NEW.admin_id  
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER user_history_insert AFTER INSERT ON users FOR EACH ROW EXECUTE PROCEDURE log_user_update();
CREATE TRIGGER user_history_update AFTER UPDATE ON users FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_user_update();


/****** ADMIN: admin HISTORY ******/
CREATE TABLE admin_history (
    id integer NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying,
    last_sign_in_ip character varying,
    failed_attempts integer DEFAULT 0,
    unlock_token character varying,
    locked_at timestamp without time zone,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    disabled boolean,
    admin_id integer
);

CREATE SEQUENCE admin_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE admin_history_id_seq OWNED BY admin_history.id;
ALTER TABLE ONLY admin_history ALTER COLUMN id SET DEFAULT nextval('admin_history_id_seq'::regclass);
ALTER TABLE ONLY admin_history ADD CONSTRAINT admin_history_pkey PRIMARY KEY (id);

CREATE INDEX index_admin_history_on_admin_id ON admin_history USING btree (admin_id);

ALTER TABLE ONLY admin_history ADD CONSTRAINT fk_admin_history_admins FOREIGN KEY (admin_id) REFERENCES admins(id);

CREATE FUNCTION log_admin_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO admin_history
            (
                    admin_id,
    email,
    encrypted_password,    
    sign_in_count,
    current_sign_in_at,
    last_sign_in_at,
    current_sign_in_ip ,
    last_sign_in_ip ,
    created_at ,
    updated_at,
    failed_attempts,
    unlock_token,
    locked_at,
    disabled 

                )                 
            SELECT                 
                NEW.id,
                NEW.email,
    NEW.encrypted_password,    
    NEW.sign_in_count,
    NEW.current_sign_in_at,
    NEW.last_sign_in_at,
    NEW.current_sign_in_ip ,
    NEW.last_sign_in_ip ,
    NEW.created_at ,
    NEW.updated_at,
    NEW.failed_attempts,
    NEW.unlock_token,
    NEW.locked_at,
    NEW.disabled 
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER admin_history_insert AFTER INSERT ON admins FOR EACH ROW EXECUTE PROCEDURE log_admin_update();
CREATE TRIGGER admin_history_update AFTER UPDATE ON admins FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_admin_update();


/****** ADMIN: protocols HISTORY ******/
CREATE TABLE protocol_history (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    "position" integer,
    protocol_id integer
);

CREATE SEQUENCE protocol_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE protocol_history_id_seq OWNED BY protocol_history.id;
ALTER TABLE ONLY protocol_history ALTER COLUMN id SET DEFAULT nextval('protocol_history_id_seq'::regclass);
ALTER TABLE ONLY protocol_history ADD CONSTRAINT protocol_history_pkey PRIMARY KEY (id);

CREATE INDEX index_protocol_history_on_protocol_id ON protocol_history USING btree (protocol_id);

ALTER TABLE ONLY protocol_history ADD CONSTRAINT fk_protocol_history_protocols FOREIGN KEY (protocol_id) REFERENCES protocols(id);

CREATE FUNCTION log_protocol_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO protocol_history
            (
                    protocol_id,
                    name ,                    
                    created_at ,
                    updated_at ,
                    disabled,
                    admin_id ,
                    "position"
                )                 
            SELECT                 
                NEW.id,
                NEW.name ,                    
                    NEW.created_at ,
                    NEW.updated_at ,
                    NEW.disabled,
                    NEW.admin_id ,
                    NEW.position
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER protocol_history_insert AFTER INSERT ON protocols FOR EACH ROW EXECUTE PROCEDURE log_protocol_update();
CREATE TRIGGER protocol_history_update AFTER UPDATE ON protocols FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_protocol_update();


/****** ADMIN: protocol_events HISTORY ******/
CREATE TABLE protocol_event_history (
    id integer NOT NULL,
    name character varying,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    sub_process_id integer,
    milestone character varying,
    description character varying,

    protocol_event_id integer
);

CREATE SEQUENCE protocol_event_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE protocol_event_history_id_seq OWNED BY protocol_event_history.id;
ALTER TABLE ONLY protocol_event_history ALTER COLUMN id SET DEFAULT nextval('protocol_event_history_id_seq'::regclass);
ALTER TABLE ONLY protocol_event_history ADD CONSTRAINT protocol_event_history_pkey PRIMARY KEY (id);

CREATE INDEX index_protocol_event_history_on_protocol_event_id ON protocol_event_history USING btree (protocol_event_id);

ALTER TABLE ONLY protocol_event_history ADD CONSTRAINT fk_protocol_event_history_protocol_events FOREIGN KEY (protocol_event_id) REFERENCES protocol_events(id);

CREATE FUNCTION log_protocol_event_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO protocol_event_history
            (
                    protocol_event_id,                    
    name ,
    admin_id,
    created_at,
    updated_at,
    disabled ,
    sub_process_id,
    milestone ,
    description

                )                 
            SELECT                 
                NEW.id,
                NEW.name ,                    
                    NEW.admin_id,
    NEW.created_at,
    NEW.updated_at,
    NEW.disabled ,
    NEW.sub_process_id,
    NEW.milestone ,
    NEW.description
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER protocol_event_history_insert AFTER INSERT ON protocol_events FOR EACH ROW EXECUTE PROCEDURE log_protocol_event_update();
CREATE TRIGGER protocol_event_history_update AFTER UPDATE ON protocol_events FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_protocol_event_update();


/****** ADMIN: sub_processes HISTORY ******/
CREATE TABLE sub_process_history (
    id integer NOT NULL,
    name character varying,
    disabled boolean,
    protocol_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,

    sub_process_id integer
);

CREATE SEQUENCE sub_process_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE sub_process_history_id_seq OWNED BY sub_process_history.id;
ALTER TABLE ONLY sub_process_history ALTER COLUMN id SET DEFAULT nextval('sub_process_history_id_seq'::regclass);
ALTER TABLE ONLY sub_process_history ADD CONSTRAINT sub_process_history_pkey PRIMARY KEY (id);

CREATE INDEX index_sub_process_history_on_sub_process_id ON sub_process_history USING btree (sub_process_id);

ALTER TABLE ONLY sub_process_history ADD CONSTRAINT fk_sub_process_history_sub_processes FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);

CREATE FUNCTION log_sub_process_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO sub_process_history
            (
                    sub_process_id,                    
    
    name,
    disabled,
    protocol_id,
    admin_id ,
    created_at,
    updated_at

                )                 
            SELECT                 
                NEW.id,
                NEW.name,
    NEW.disabled,
    NEW.protocol_id,
    NEW.admin_id ,
    NEW.created_at,
    NEW.updated_at
            ;
            RETURN NEW;
        END;
    $$;

CREATE TRIGGER sub_process_history_insert AFTER INSERT ON sub_processes FOR EACH ROW EXECUTE PROCEDURE log_sub_process_update();
CREATE TRIGGER sub_process_history_update AFTER UPDATE ON sub_processes FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_sub_process_update();
