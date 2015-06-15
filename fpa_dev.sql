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

SET default_tablespace = '';

SET default_with_oids = false;

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
    updated_at timestamp without time zone NOT NULL
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
    synonym_for_id integer
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
-- Name: manual_investigations; Type: TABLE; Schema: public; Owner: phil; Tablespace: 
--

CREATE TABLE manual_investigations (
    id integer NOT NULL,
    fill_in_addresses character varying(1),
    in_survey character varying(1),
    verify_survey_participation character varying(1),
    verify_player_and_or_match character varying(1),
    accuracy character varying(15),
    accuracy_score integer,
    changed_column character varying,
    verified integer,
    pilotq1 integer,
    mailing integer,
    outreach_vfy integer,
    insert_audit_key integer,
    user_id integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    rank integer,
    master_id integer,
    is_changed integer,
    scantron_id integer
);


ALTER TABLE public.manual_investigations OWNER TO phil;

--
-- Name: manual_investigations_id_seq; Type: SEQUENCE; Schema: public; Owner: phil
--

CREATE SEQUENCE manual_investigations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.manual_investigations_id_seq OWNER TO phil;

--
-- Name: manual_investigations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: phil
--

ALTER SEQUENCE manual_investigations_id_seq OWNED BY manual_investigations.id;


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
    updated_at timestamp without time zone NOT NULL
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
    updated_at timestamp without time zone NOT NULL,
    contact_pref character varying,
    start_year integer,
    in_survey character varying(1),
    rank integer,
    notes character varying
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
    birth_date character varying,
    death_date character varying,
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
    updated_at timestamp without time zone NOT NULL,
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

ALTER TABLE ONLY manage_users ALTER COLUMN id SET DEFAULT nextval('manage_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY manual_investigations ALTER COLUMN id SET DEFAULT nextval('manual_investigations_id_seq'::regclass);


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

ALTER TABLE ONLY scantrons ALTER COLUMN id SET DEFAULT nextval('scantrons_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: phil
--

ALTER TABLE ONLY users ALTER COLUMN id SET DEFAULT nextval('users_id_seq'::regclass);


--
-- Data for Name: addresses; Type: TABLE DATA; Schema: public; Owner: phil
--

COPY addresses (id, master_id, street, street2, street3, city, state, zip, source, rank, rec_type, user_id, created_at, updated_at) FROM stdin;
1	1	Test St	\N	\N	Boston	MA	02115	PRO	1	HOME	\N	2015-06-11 09:48:45.409382	2015-06-11 09:48:45.409382
\.


--
-- Name: addresses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phil
--

SELECT pg_catalog.setval('addresses_id_seq', 1, true);


--
-- Data for Name: admins; Type: TABLE DATA; Schema: public; Owner: phil
--

COPY admins (id, email, encrypted_password, sign_in_count, current_sign_in_at, last_sign_in_at, current_sign_in_ip, last_sign_in_ip, failed_attempts, unlock_token, locked_at, created_at, updated_at) FROM stdin;
2	initialadmin@hms.harvard.edu-not	$2a$10$0aAiH4zq2jPArEIYv6m4m.7tAZstu5Iv8Fd7xqrZslyzFhA.cnDSi	0	\N	\N	\N	\N	0	\N	\N	2015-06-03 21:13:00.096075	2015-06-03 21:13:00.096075
3	initialadmin@hms.harvard.edu	$2a$10$2r5PsY8ZpyIxFxBbHi55fuqH8ZD.5zYq5cSlVCeoRevK0Jyg40zUu	0	\N	\N	\N	\N	0	\N	\N	2015-06-03 21:13:58.71162	2015-06-03 21:13:58.71162
1	initialadmin@hms.harvard.edu-not	$2a$10$gyRNCh80Vo4TcK.6b7qCgeWYio0FniN6SoNVQnvpxmiIOfCKYNEAy	4	2015-06-03 21:26:07.511205	2015-06-03 17:08:29.646238	127.0.0.1	127.0.0.1	0	\N	\N	2015-06-03 14:24:11.233312	2015-06-03 21:26:07.51191
\.


--
-- Name: admins_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phil
--

SELECT pg_catalog.setval('admins_id_seq', 3, true);


--
-- Data for Name: colleges; Type: TABLE DATA; Schema: public; Owner: phil
--

COPY colleges (id, name, synonym_for_id) FROM stdin;
2	Boston College	\N
3	Boston University	\N
4	Northeastern	\N
5	University of Massachusetts	\N
1	Harvard University	\N
\.


--
-- Name: colleges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phil
--

SELECT pg_catalog.setval('colleges_id_seq', 5, true);


--
-- Data for Name: manage_users; Type: TABLE DATA; Schema: public; Owner: phil
--

COPY manage_users (id, created_at, updated_at) FROM stdin;
1	2015-06-03 17:10:01.679635	2015-06-03 17:10:01.679635
\.


--
-- Name: manage_users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phil
--

SELECT pg_catalog.setval('manage_users_id_seq', 1, true);


--
-- Data for Name: manual_investigations; Type: TABLE DATA; Schema: public; Owner: phil
--

COPY manual_investigations (id, fill_in_addresses, in_survey, verify_survey_participation, verify_player_and_or_match, accuracy, accuracy_score, changed_column, verified, pilotq1, mailing, outreach_vfy, insert_audit_key, user_id, created_at, updated_at, rank, master_id, is_changed, scantron_id) FROM stdin;
1	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	2015-06-11 09:50:54.769437	2015-06-11 09:50:54.769437	\N	1	\N	\N
\.


--
-- Name: manual_investigations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phil
--

SELECT pg_catalog.setval('manual_investigations_id_seq', 1, true);


--
-- Data for Name: masters; Type: TABLE DATA; Schema: public; Owner: phil
--

COPY masters (id) FROM stdin;
1
\.


--
-- Name: masters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phil
--

SELECT pg_catalog.setval('masters_id_seq', 1, true);


--
-- Data for Name: player_contacts; Type: TABLE DATA; Schema: public; Owner: phil
--

COPY player_contacts (id, master_id, rec_type, data, source, rank, active, user_id, created_at, updated_at) FROM stdin;
1	1	EMAIL	test-player@test.com	PRO	1	t	\N	2015-06-11 09:51:31.906455	2015-06-11 09:51:31.906455
\.


--
-- Name: player_contacts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phil
--

SELECT pg_catalog.setval('player_contacts_id_seq', 1, true);


--
-- Data for Name: player_infos; Type: TABLE DATA; Schema: public; Owner: phil
--

COPY player_infos (id, master_id, first_name, last_name, middle_name, nick_name, birth_date, death_date, occupation_category, company, company_description, transaction_status, transaction_substatus, user_id, created_at, updated_at, contact_pref, start_year, in_survey, rank, notes) FROM stdin;
1	1	Robert	Smith	Arnold	Barnie	2015-06-11	2015-06-11	\N	\N	\N	\N	\N	\N	2015-06-11 09:52:29.418981	2015-06-11 09:52:29.418981	\N	\N	\N	2	\N
2	1	Bob	Smith	\N	\N	2015-06-11	2015-06-11	\N	\N	\N	\N	\N	\N	2015-06-11 09:53:41.640482	2015-06-11 09:53:41.640482	\N	\N	\N	1	\N
\.


--
-- Name: player_infos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phil
--

SELECT pg_catalog.setval('player_infos_id_seq', 4, true);


--
-- Data for Name: pro_infos; Type: TABLE DATA; Schema: public; Owner: phil
--

COPY pro_infos (id, master_id, pro_id, in_survey, first_name, middle_name, nick_name, last_name, birth_date, death_date, start_year, end_year, accrued_seasons, college, first_contract, second_contract, third_contract, career_info, birthplace, user_id, created_at, updated_at, rank) FROM stdin;
1	1	\N	\N	Robert		\N	Smith	\N	\N	1967	1969	1	\N	\N	\N	\N	\N	\N	\N	2015-06-11 09:53:22.131363	2015-06-11 09:53:22.131363	\N
\.


--
-- Name: pro_infos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phil
--

SELECT pg_catalog.setval('pro_infos_id_seq', 1, true);


--
-- Data for Name: scantrons; Type: TABLE DATA; Schema: public; Owner: phil
--

COPY scantrons (id, master_id, scantron_id, source, rank, user_id, created_at, updated_at) FROM stdin;
\.


--
-- Name: scantrons_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phil
--

SELECT pg_catalog.setval('scantrons_id_seq', 1, false);


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: phil
--

COPY schema_migrations (version) FROM stdin;
20150602181200
20150602181229
20150602181400
20150602181925
20150602205642
20150603135202
20150603153758
20150603170429
20150609140033
20150609150931
20150609160545
20150604160659
20150609161656
20150609185229
20150609185749
20150609190556
20150610142403
20150610143629
20150610155810
20150610160257
20150610183502
20150610220253
20150610220320
20150610220451
20150611144834
20150611145259
20150611180303
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: phil
--

COPY users (id, email, encrypted_password, reset_password_token, reset_password_sent_at, remember_created_at, sign_in_count, current_sign_in_at, last_sign_in_at, current_sign_in_ip, last_sign_in_ip, created_at, updated_at, failed_attempts, unlock_token, locked_at) FROM stdin;
1			\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 17:21:18.630366	2015-06-03 17:21:18.630366	0	\N	\N
14	asdjfkhsdjfhj@jhjshdfjhsjfh.com		\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 17:33:23.613319	2015-06-03 17:33:23.613319	0	\N	\N
19	asddjfkhsdjfhj@jhjshdfjhsjfh.com	$2a$10$dNW7n1zCKlbaB5iU7pLDB.2j4QSVcqSftUASd9KZZkf8CQsai2FIa	\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 17:39:13.186465	2015-06-03 17:39:13.186465	0	\N	\N
21	asddjfkhasdfasdfsdjfhj@jhjshdfjhsjfh.com	$2a$10$ktejjf5rRiZg9cVjut4tiO0yO4m6fBnVgwsQqLexoIrwv6ykC4t5.	\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 17:39:26.369885	2015-06-03 17:39:26.369885	0	\N	\N
23	asddjfkhasddfasdfsdjfhj@jhjshdfjhsjfh.com	$2a$10$xiyG4G41D99R0N0I7ZwNhOTExn7aVWN2IBgv4D.uRhRIpZglbK8Vm	\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 17:39:49.110449	2015-06-03 17:39:49.110449	0	\N	\N
25	asddjfkhasddfasddfsdjfhj@jhjshdfjhsjfh.com	$2a$10$oTVzVZE/EAJqmteZhEsAGufWcoxrev.PHc9qZ/GOCLK6IFzIy3URm	\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 17:40:26.78291	2015-06-03 17:40:26.78291	0	\N	\N
27	asddjfkhasddfasddsfsdjfhj@jhjshdfjhsjfh.com	$2a$10$LRIMu1VDtytBV4Xb.9vvN.eyncCs8Z3kh5JtBhd8.YBkEltbP9WZa	\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 17:40:53.823919	2015-06-03 17:40:53.823919	0	\N	\N
28	asdkjfhkshf@kjhkashfdkhsadkfh.com		\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 18:04:37.078746	2015-06-03 18:04:37.078746	0	\N	\N
30	asdkjfhkshf@kjhkashfddkhsadkfh.com		\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 18:04:53.648049	2015-06-03 18:04:53.648049	0	\N	\N
32	dasdkjfhkshf@kjhkashfddkhsadkfh.com		\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 18:05:31.073642	2015-06-03 18:05:31.073642	0	\N	\N
35	dasddkjfhkshf@kjhkashfddkhsadkfh.com		\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 18:06:50.917422	2015-06-03 18:06:50.917422	0	\N	\N
37	dasddkjfhksshf@kjhkashfddkhsadkfh.com	$2a$10$K1PzgTITfFpyPRbCx0TiDur.Nc5H2Grp6VH1YWgkA6m4OG2LBuqc6	\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 18:07:20.970633	2015-06-03 18:26:30.369265	0	\N	\N
38	asdmfjhsdfkjh@jkhksajddhfkjhs.com	$2a$10$hTcVAsEvyopGFpUG/4TuzeyldWpScb12EvzxDipNrB0NuAFEphCTS	\N	\N	\N	2	2015-06-03 18:30:59.363088	2015-06-03 18:27:54.592963	127.0.0.1	127.0.0.1	2015-06-03 18:26:55.947847	2015-06-03 18:30:59.363759	0	\N	\N
34	dasdkjfhkshf@kjhkashdfddkhsadkfh.com	$2a$10$xv.IxAwIyQ/4ZymvrEj.G.W8C/Mr6GK10TD9vjMBO988oA08fVaw6	\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 18:05:47.164781	2015-06-03 18:33:46.249902	0	\N	\N
39	fsdaf@kjhkjhkjhkj	$2a$10$/rzcN3AkUQfapu8wAoZeh.jf.HxIC.733SevwWWA1WqZ8VQYCYg/6	\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 18:34:37.628421	2015-06-03 18:34:37.628421	0	\N	\N
40	fsdaf@kjhkjhkjhdkdsj.com	$2a$10$71duv9gu179mlR4oIg1kTe5dqkL.koXklJAHY3oApUjSPMxm9OrNC	\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 18:42:38.361385	2015-06-03 18:42:38.361385	0	\N	\N
41	fsdaf@kjhkjhkjhkj.com	$2a$10$pqPIjJ/VoU/sRMU/lqyHnu6.Ra8ykz6Z1Ln1dpQP0hvhOlGcZyhU2	\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 18:43:05.747585	2015-06-03 18:43:05.747585	0	\N	\N
42	fsdaf@kjhkjhkjdhkj.com	$2a$10$kFPSxAqQAiCgSLyBk63mrOMQvpupzGcij1OSAaOmf6tXJhOju9tvS	\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 18:44:47.082232	2015-06-03 18:44:47.082232	0	\N	\N
43	sdfsdf@kjhkasdfhf.com	$2a$10$xd0PmeoMMwLuLjkqw223futODriHRrdAK.w9N8Bo2Tmji0lU.IyRa	\N	\N	\N	0	\N	\N	\N	\N	2015-06-03 18:44:54.374436	2015-06-03 18:44:54.374436	0	\N	\N
44	phil_ayres@test.com	$2a$10$6s8EtRRTvYT/5i1FyfPzEu9aNIy//XXp//JcAD2k3FafSrIjJ/70a	\N	\N	\N	17	2015-06-11 19:00:28.072016	2015-06-11 16:37:00.845733	10.119.214.177	127.0.0.1	2015-06-03 21:05:36.950578	2015-06-11 19:00:28.073693	0	\N	\N
\.


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: phil
--

SELECT pg_catalog.setval('users_id_seq', 44, true);


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
-- Name: manage_users_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY manage_users
    ADD CONSTRAINT manage_users_pkey PRIMARY KEY (id);


--
-- Name: manual_investigations_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY manual_investigations
    ADD CONSTRAINT manual_investigations_pkey PRIMARY KEY (id);


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
-- Name: scantrons_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT scantrons_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: phil; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: index_addresses_on_master_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_addresses_on_master_id ON addresses USING btree (master_id);


--
-- Name: index_addresses_on_user_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_addresses_on_user_id ON addresses USING btree (user_id);


--
-- Name: index_manual_investigations_on_master_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_manual_investigations_on_master_id ON manual_investigations USING btree (master_id);


--
-- Name: index_manual_investigations_on_scantron_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_manual_investigations_on_scantron_id ON manual_investigations USING btree (scantron_id);


--
-- Name: index_manual_investigations_on_user_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_manual_investigations_on_user_id ON manual_investigations USING btree (user_id);


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
-- Name: index_scantrons_on_master_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_scantrons_on_master_id ON scantrons USING btree (master_id);


--
-- Name: index_scantrons_on_user_id; Type: INDEX; Schema: public; Owner: phil; Tablespace: 
--

CREATE INDEX index_scantrons_on_user_id ON scantrons USING btree (user_id);


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
-- Name: fk_rails_08e7f66647; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT fk_rails_08e7f66647 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_1a7e2b01e0; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT fk_rails_1a7e2b01e0 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_20667815e3; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT fk_rails_20667815e3 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_23cd255bc6; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY player_infos
    ADD CONSTRAINT fk_rails_23cd255bc6 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_45205ed085; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY scantrons
    ADD CONSTRAINT fk_rails_45205ed085 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_48c9e0c5a2; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT fk_rails_48c9e0c5a2 FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_6506a76379; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY manual_investigations
    ADD CONSTRAINT fk_rails_6506a76379 FOREIGN KEY (scantron_id) REFERENCES scantrons(id);


--
-- Name: fk_rails_72b1afe72f; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT fk_rails_72b1afe72f FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: fk_rails_86cecb1e36; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY pro_infos
    ADD CONSTRAINT fk_rails_86cecb1e36 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_a44670b00a; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY addresses
    ADD CONSTRAINT fk_rails_a44670b00a FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_a76c5947ea; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY manual_investigations
    ADD CONSTRAINT fk_rails_a76c5947ea FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_d3c0ddde90; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY player_contacts
    ADD CONSTRAINT fk_rails_d3c0ddde90 FOREIGN KEY (master_id) REFERENCES masters(id);


--
-- Name: fk_rails_e6e149db7b; Type: FK CONSTRAINT; Schema: public; Owner: phil
--

ALTER TABLE ONLY manual_investigations
    ADD CONSTRAINT fk_rails_e6e149db7b FOREIGN KEY (user_id) REFERENCES users(id);


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

