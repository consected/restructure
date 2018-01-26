--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

SET search_path = ml_app, pg_catalog;

--
-- Data for Name: app_configurations; Type: TABLE DATA; Schema: ml_app; Owner: -
--

COPY app_configurations (id, name, value, disabled, admin_id, user_id) FROM stdin;
2	menu create master record label	New Player Record	f	15	\N
5	hide search form advanced	true	f	15	\N
6	hide search form searchable reports	false	f	15	\N
14	user session timeout	30	f	15	\N
1	notes field caption	no medical information	f	15	\N
3	menu research label	Research	f	15	\N
4	hide search form simple	false	f	15	\N
9	hide tracker panel	false	f	15	\N
8	hide pro info	false	f	15	\N
10	hide player tabs	false	f	15	\N
12	hide player accuracy	false	f	15	\N
7	default search form	Simple Search	f	15	\N
11	show activity log panel		f	15	\N
13	hide navbar search	false	f	15	\N
15	hide navbar search	true	f	15	44
\.


--
-- Name: app_configurations_id_seq; Type: SEQUENCE SET; Schema: ml_app; Owner: -
--

SELECT pg_catalog.setval('app_configurations_id_seq', 15, true);


--
-- PostgreSQL database dump complete
--

