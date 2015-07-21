--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: log_tracker_update(); Type: FUNCTION; Schema: public; Owner: phil
--

CREATE FUNCTION log_tracker_update() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO tracker_history 
                (tracker_id, master_id, protocol_id, 
                 protocol_event_id, event_date, sub_process_id, notes,
                 created_at, updated_at, user_id)
                 
            SELECT NEW.id, NEW.master_id, NEW.protocol_id, 
                   NEW.protocol_event_id, NEW.event_date, 
                   NEW.sub_process_id, NEW.notes, 
                   NEW.created_at, NEW.updated_at, NEW.user_id  ;
            RETURN NEW;
        END;
    $$;


ALTER FUNCTION public.log_tracker_update() OWNER TO phil;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: accuracy_scores; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE accuracy_scores (
    id integer NOT NULL,
    name character varying,
    value integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean
);


ALTER TABLE public.accuracy_scores OWNER TO phil;

--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE accuracy_scores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.accuracy_scores_id_seq OWNER TO phil;

--
-- Name: accuracy_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE accuracy_scores_id_seq OWNED BY accuracy_scores.id;


--
-- Name: addresses; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE addresses (
    id integer NOT NULL,
    master_id integer,
    street character varying,
    street2 character varying,
    street3 character varying,
    city character varying,
    state character varying,
    zip character varying,
    source character varying,
    rank integer,
    rec_type character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.addresses OWNER TO phil;

--
-- Name: addresses_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE addresses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.addresses_id_seq OWNER TO phil;

--
-- Name: addresses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE addresses_id_seq OWNED BY addresses.id;


--
-- Name: admins; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE admins (
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
    updated_at timestamp without time zone
);


ALTER TABLE public.admins OWNER TO phil;

--
-- Name: admins_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE admins_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.admins_id_seq OWNER TO phil;

--
-- Name: admins_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE admins_id_seq OWNED BY admins.id;


--
-- Name: colleges; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE colleges (
    id integer NOT NULL,
    name character varying,
    synonym_for_id integer,
    disabled boolean
);


ALTER TABLE public.colleges OWNER TO phil;

--
-- Name: colleges_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE colleges_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.colleges_id_seq OWNER TO phil;

--
-- Name: colleges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE colleges_id_seq OWNED BY colleges.id;


--
-- Name: general_selections; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE general_selections (
    id integer NOT NULL,
    name character varying,
    value character varying,
    item_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer
);


ALTER TABLE public.general_selections OWNER TO phil;

--
-- Name: general_selections_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE general_selections_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.general_selections_id_seq OWNER TO phil;

--
-- Name: general_selections_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE general_selections_id_seq OWNED BY general_selections.id;


--
-- Name: item_flag_names; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE item_flag_names (
    id integer NOT NULL,
    name character varying,
    item_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer
);


ALTER TABLE public.item_flag_names OWNER TO phil;

--
-- Name: item_flag_names_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE item_flag_names_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.item_flag_names_id_seq OWNER TO phil;

--
-- Name: item_flag_names_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE item_flag_names_id_seq OWNED BY item_flag_names.id;


--
-- Name: item_flags; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE item_flags (
    id integer NOT NULL,
    item_id integer,
    item_type character varying,
    item_flag_name_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    user_id integer
);


ALTER TABLE public.item_flags OWNER TO phil;

--
-- Name: item_flags_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE item_flags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.item_flags_id_seq OWNER TO phil;

--
-- Name: item_flags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE item_flags_id_seq OWNED BY item_flags.id;


--
-- Name: manage_users; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE manage_users (
    id integer NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.manage_users OWNER TO phil;

--
-- Name: manage_users_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE manage_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.manage_users_id_seq OWNER TO phil;

--
-- Name: manage_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE manage_users_id_seq OWNED BY manage_users.id;


--
-- Name: masters; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE masters (
    id integer NOT NULL
);


ALTER TABLE public.masters OWNER TO phil;

--
-- Name: masters_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE masters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.masters_id_seq OWNER TO phil;

--
-- Name: masters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE masters_id_seq OWNED BY masters.id;


--
-- Name: player_contacts; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE player_contacts (
    id integer NOT NULL,
    master_id integer,
    rec_type character varying,
    data character varying,
    source character varying,
    rank integer,
    active boolean,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    active_date date
);


ALTER TABLE public.player_contacts OWNER TO phil;

--
-- Name: player_contacts_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE player_contacts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.player_contacts_id_seq OWNER TO phil;

--
-- Name: player_contacts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE player_contacts_id_seq OWNED BY player_contacts.id;


--
-- Name: player_infos; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE player_infos (
    id integer NOT NULL,
    master_id integer,
    first_name character varying,
    last_name character varying,
    middle_name character varying,
    nick_name character varying,
    birth_date date,
    death_date date,
    occupation_category character varying,
    company character varying,
    company_description character varying,
    transaction_status character varying,
    transaction_substatus character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    contact_pref character varying,
    start_year integer,
    in_survey character varying(1),
    rank integer,
    notes character varying,
    contact_id integer,
    pro_info_id integer,
    college character varying,
    end_year integer
);


ALTER TABLE public.player_infos OWNER TO phil;

--
-- Name: player_infos_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE player_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.player_infos_id_seq OWNER TO phil;

--
-- Name: player_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE player_infos_id_seq OWNED BY player_infos.id;


--
-- Name: pro_infos; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE pro_infos (
    id integer NOT NULL,
    master_id integer,
    pro_id integer,
    in_survey character varying,
    first_name character varying,
    middle_name character varying,
    nick_name character varying,
    last_name character varying,
    birth_date date,
    death_date date,
    start_year integer,
    end_year integer,
    accrued_seasons numeric,
    college character varying,
    first_contract character varying,
    second_contract character varying,
    third_contract character varying,
    career_info character varying,
    birthplace character varying,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone DEFAULT now(),
    rank integer
);


ALTER TABLE public.pro_infos OWNER TO phil;

--
-- Name: pro_infos_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE pro_infos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pro_infos_id_seq OWNER TO phil;

--
-- Name: pro_infos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE pro_infos_id_seq OWNED BY pro_infos.id;


--
-- Name: protocol_events; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE protocol_events (
    id integer NOT NULL,
    name character varying,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    sub_process_id integer,
    milestone character varying,
    description character varying
);


ALTER TABLE public.protocol_events OWNER TO phil;

--
-- Name: protocol_events_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE protocol_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.protocol_events_id_seq OWNER TO phil;

--
-- Name: protocol_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE protocol_events_id_seq OWNED BY protocol_events.id;


--
-- Name: protocols; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE protocols (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    disabled boolean,
    admin_id integer,
    "position" integer
);


ALTER TABLE public.protocols OWNER TO phil;

--
-- Name: protocols_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE protocols_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.protocols_id_seq OWNER TO phil;

--
-- Name: protocols_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE protocols_id_seq OWNED BY protocols.id;


--
-- Name: scantrons; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE scantrons (
    id integer NOT NULL,
    master_id integer,
    scantron_id integer,
    source character varying,
    rank integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.scantrons OWNER TO phil;

--
-- Name: scantrons_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE scantrons_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scantrons_id_seq OWNER TO phil;

--
-- Name: scantrons_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE scantrons_id_seq OWNED BY scantrons.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO phil;

--
-- Name: sub_processes; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE sub_processes (
    id integer NOT NULL,
    name character varying,
    disabled boolean,
    protocol_id integer,
    admin_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


ALTER TABLE public.sub_processes OWNER TO phil;

--
-- Name: sub_processes_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE sub_processes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sub_processes_id_seq OWNER TO phil;

--
-- Name: sub_processes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE sub_processes_id_seq OWNED BY sub_processes.id;


--
-- Name: tracker_history; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE tracker_history (
    id integer NOT NULL,
    master_id integer,
    protocol_id integer,
    tracker_id integer,
    event character varying,
    event_date timestamp without time zone,
    c_method character varying,
    outcome character varying,
    outcome_date timestamp without time zone,
    user_id integer,
    notes character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    sub_process_id integer,
    protocol_event_id integer,
    item_id integer,
    item_type character varying
);


ALTER TABLE public.tracker_history OWNER TO phil;

--
-- Name: tracker_history_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE tracker_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tracker_history_id_seq OWNER TO phil;

--
-- Name: tracker_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE tracker_history_id_seq OWNED BY tracker_history.id;


--
-- Name: trackers; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE trackers (
    id integer NOT NULL,
    master_id integer,
    protocol_id integer,
    event character varying,
    event_date timestamp without time zone,
    c_method character varying,
    outcome character varying,
    outcome_date timestamp without time zone,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    notes character varying,
    sub_process_id integer,
    protocol_event_id integer,
    item_id integer,
    item_type character varying
);


ALTER TABLE public.trackers OWNER TO phil;

--
-- Name: trackers_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE trackers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.trackers_id_seq OWNER TO phil;

--
-- Name: trackers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE trackers_id_seq OWNED BY trackers.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE users (
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
    locked_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO phil;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO phil;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE users_id_seq OWNED BY users.id;


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY accuracy_scores ALTER COLUMN id SET DEFAULT nextval('accuracy_scores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY addresses ALTER COLUMN id SET DEFAULT nextval('addresses_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY admins ALTER COLUMN id SET DEFAULT nextval('admins_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY colleges ALTER COLUMN id SET DEFAULT nextval('colleges_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY general_selections ALTER COLUMN id SET DEFAULT nextval('general_selections_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY item_flag_names ALTER COLUMN id SET DEFAULT nextval('item_flag_names_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY item_flags ALTER COLUMN id SET DEFAULT nextval('item_flags_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY manage_users ALTER COLUMN id SET DEFAULT nextval('manage_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY masters ALTER COLUMN id SET DEFAULT nextval('masters_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY player_contacts ALTER COLUMN id SET DEFAULT nextval('player_contacts_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY player_infos ALTER COLUMN id SET DEFAULT nextval('player_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY pro_infos ALTER COLUMN id SET DEFAULT nextval('pro_infos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY protocol_events ALTER COLUMN id SET DEFAULT nextval('protocol_events_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY protocols ALTER COLUMN id SET DEFAULT nextval('protocols_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY scantrons ALTER COLUMN id SET DEFAULT nextval('scantrons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY sub_processes ALTER COLUMN id SET DEFAULT nextval('sub_processes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY tracker_history ALTER COLUMN id SET DEFAULT nextval('tracker_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY trackers ALTER COLUMN id SET DEFAULT nextval('trackers_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Name: accuracy_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY accuracy_scores
    ADD CONSTRAINT accuracy_scores_pkey PRIMARY KEY (id);


--
-- Name: addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: admins_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY admins
    ADD CONSTRAINT admins_pkey PRIMARY KEY (id);


--
-- Name: colleges_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY colleges
    ADD CONSTRAINT colleges_pkey PRIMARY KEY (id);


--
-- Name: general_selections_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY general_selections
    ADD CONSTRAINT general_selections_pkey PRIMARY KEY (id);


--
-- Name: item_flag_names_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY item_flag_names
    ADD CONSTRAINT item_flag_names_pkey PRIMARY KEY (id);


--
-- Name: item_flags_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY item_flags
    ADD CONSTRAINT item_flags_pkey PRIMARY KEY (id);


--
-- Name: manage_users_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY manage_users
    ADD CONSTRAINT manage_users_pkey PRIMARY KEY (id);


--
-- Name: masters_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY masters
    ADD CONSTRAINT masters_pkey PRIMARY KEY (id);


--
-- Name: player_contacts_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT player_contacts_pkey PRIMARY KEY (id);


--
-- Name: player_infos_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT player_infos_pkey PRIMARY KEY (id);


--
-- Name: pro_infos_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT pro_infos_pkey PRIMARY KEY (id);


--
-- Name: protocol_events_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY protocol_events
    ADD CONSTRAINT protocol_events_pkey PRIMARY KEY (id);


--
-- Name: protocols_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY protocols
    ADD CONSTRAINT protocols_pkey PRIMARY KEY (id);


--
-- Name: scantrons_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT scantrons_pkey PRIMARY KEY (id);


--
-- Name: sub_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY sub_processes
    ADD CONSTRAINT sub_processes_pkey PRIMARY KEY (id);


--
-- Name: tracker_history_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT tracker_history_pkey PRIMARY KEY (id);


--
-- Name: trackers_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT trackers_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_accuracy_scores_on_admin_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_accuracy_scores_on_admin_id ON accuracy_scores USING btree (admin_id);


--
-- Name: index_addresses_on_master_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_addresses_on_master_id ON addresses USING btree (master_id);


--
-- Name: index_addresses_on_user_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_addresses_on_user_id ON addresses USING btree (user_id);


--
-- Name: index_general_selections_on_admin_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_general_selections_on_admin_id ON general_selections USING btree (admin_id);


--
-- Name: index_item_flag_names_on_admin_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_item_flag_names_on_admin_id ON item_flag_names USING btree (admin_id);


--
-- Name: index_item_flags_on_item_flag_name_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_item_flags_on_item_flag_name_id ON item_flags USING btree (item_flag_name_id);


--
-- Name: index_item_flags_on_user_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_item_flags_on_user_id ON item_flags USING btree (user_id);


--
-- Name: index_player_contacts_on_master_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_player_contacts_on_master_id ON player_contacts USING btree (master_id);


--
-- Name: index_player_contacts_on_user_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_player_contacts_on_user_id ON player_contacts USING btree (user_id);


--
-- Name: index_player_infos_on_master_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_player_infos_on_master_id ON player_infos USING btree (master_id);


--
-- Name: index_player_infos_on_pro_info_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_player_infos_on_pro_info_id ON player_infos USING btree (pro_info_id);


--
-- Name: index_player_infos_on_user_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_player_infos_on_user_id ON player_infos USING btree (user_id);


--
-- Name: index_pro_infos_on_master_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_pro_infos_on_master_id ON pro_infos USING btree (master_id);


--
-- Name: index_pro_infos_on_user_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_pro_infos_on_user_id ON pro_infos USING btree (user_id);


--
-- Name: index_protocol_events_on_admin_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_protocol_events_on_admin_id ON protocol_events USING btree (admin_id);


--
-- Name: index_protocol_events_on_sub_process_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_protocol_events_on_sub_process_id ON protocol_events USING btree (sub_process_id);


--
-- Name: index_protocols_on_admin_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_protocols_on_admin_id ON protocols USING btree (admin_id);


--
-- Name: index_scantrons_on_master_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_scantrons_on_master_id ON scantrons USING btree (master_id);


--
-- Name: index_scantrons_on_user_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_scantrons_on_user_id ON scantrons USING btree (user_id);


--
-- Name: index_sub_processes_on_admin_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_sub_processes_on_admin_id ON sub_processes USING btree (admin_id);


--
-- Name: index_sub_processes_on_protocol_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_sub_processes_on_protocol_id ON sub_processes USING btree (protocol_id);


--
-- Name: index_tracker_history_on_master_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_tracker_history_on_master_id ON tracker_history USING btree (master_id);


--
-- Name: index_tracker_history_on_protocol_event_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_tracker_history_on_protocol_event_id ON tracker_history USING btree (protocol_event_id);


--
-- Name: index_tracker_history_on_protocol_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_tracker_history_on_protocol_id ON tracker_history USING btree (protocol_id);


--
-- Name: index_tracker_history_on_sub_process_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_tracker_history_on_sub_process_id ON tracker_history USING btree (sub_process_id);


--
-- Name: index_tracker_history_on_tracker_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_tracker_history_on_tracker_id ON tracker_history USING btree (tracker_id);


--
-- Name: index_tracker_history_on_user_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_tracker_history_on_user_id ON tracker_history USING btree (user_id);


--
-- Name: index_trackers_on_master_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_trackers_on_master_id ON trackers USING btree (master_id);


--
-- Name: index_trackers_on_protocol_event_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_trackers_on_protocol_event_id ON trackers USING btree (protocol_event_id);


--
-- Name: index_trackers_on_protocol_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_trackers_on_protocol_id ON trackers USING btree (protocol_id);


--
-- Name: index_trackers_on_sub_process_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_trackers_on_sub_process_id ON trackers USING btree (sub_process_id);


--
-- Name: index_trackers_on_user_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_trackers_on_user_id ON trackers USING btree (user_id);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_email ON users USING btree (email);


--
-- Name: index_users_on_reset_password_token; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_reset_password_token ON users USING btree (reset_password_token);


--
-- Name: index_users_on_unlock_token; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE UNIQUE INDEX index_users_on_unlock_token ON users USING btree (unlock_token);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: tracker_history_insert; Type: TRIGGER; Schema: public; Owner: phil
--

CREATE TRIGGER tracker_history_insert AFTER INSERT ON trackers FOR EACH ROW EXECUTE PROCEDURE log_tracker_update();


--
-- Name: tracker_history_update; Type: TRIGGER; Schema: public; Owner: phil
--

CREATE TRIGGER tracker_history_update AFTER UPDATE ON trackers FOR EACH ROW WHEN ((old.* IS DISTINCT FROM new.*)) EXECUTE PROCEDURE log_tracker_update();


--
-- Name: fk_rails_08e7f66647; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT fk_rails_08e7f66647 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_0a64e1160a; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY protocol_events
    ADD CONSTRAINT fk_rails_0a64e1160a FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_1fc7475261; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY sub_processes
    ADD CONSTRAINT fk_rails_1fc7475261 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_20667815e3; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT fk_rails_20667815e3 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_22ccfd95e1; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY item_flag_names
    ADD CONSTRAINT fk_rails_22ccfd95e1 FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_23cd255bc6; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT fk_rails_23cd255bc6 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_447d125f63; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_447d125f63 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_47b051d356; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_47b051d356 FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_rails_48c9e0c5a2; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT fk_rails_48c9e0c5a2 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_564af80fb6; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY protocol_events
    ADD CONSTRAINT fk_rails_564af80fb6 FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_rails_623e0ca5ac; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_623e0ca5ac FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_6de4fd560d; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY protocols
    ADD CONSTRAINT fk_rails_6de4fd560d FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_6e050927c2; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_6e050927c2 FOREIGN KEY (tracker_id) REFERENCES trackers(id);


--
-- Name: fk_rails_70c17e88fd; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY accuracy_scores
    ADD CONSTRAINT fk_rails_70c17e88fd FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_72b1afe72f; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT fk_rails_72b1afe72f FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_7c10a99849; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY sub_processes
    ADD CONSTRAINT fk_rails_7c10a99849 FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_83aa075398; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_83aa075398 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_86cecb1e36; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT fk_rails_86cecb1e36 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_9513fd1c35; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_9513fd1c35 FOREIGN KEY (sub_process_id) REFERENCES sub_processes(id);


--
-- Name: fk_rails_9e92bdfe65; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_9e92bdfe65 FOREIGN KEY (protocol_event_id) REFERENCES protocol_events(id);


--
-- Name: fk_rails_9f5797d684; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_9f5797d684 FOREIGN KEY (protocol_id) REFERENCES protocols(id);


--
-- Name: fk_rails_a44670b00a; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT fk_rails_a44670b00a FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_b822840dc1; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_b822840dc1 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_bb6af37155; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY trackers
    ADD CONSTRAINT fk_rails_bb6af37155 FOREIGN KEY (protocol_event_id) REFERENCES protocol_events(id);


--
-- Name: fk_rails_c2d5bb8930; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY item_flags
    ADD CONSTRAINT fk_rails_c2d5bb8930 FOREIGN KEY (item_flag_name_id) REFERENCES item_flag_names(id);


--
-- Name: fk_rails_c55341c576; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY tracker_history
    ADD CONSTRAINT fk_rails_c55341c576 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_d3c0ddde90; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT fk_rails_d3c0ddde90 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_dce5169cfd; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY item_flags
    ADD CONSTRAINT fk_rails_dce5169cfd FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_f62500107f; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY general_selections
    ADD CONSTRAINT fk_rails_f62500107f FOREIGN KEY (admin_id) REFERENCES admins(id);


--
-- Name: fk_rails_fcdbb68b71; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT fk_rails_fcdbb68b71 FOREIGN KEY (pro_info_id) REFERENCES pro_infos(id);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

