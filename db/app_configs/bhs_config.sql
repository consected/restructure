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

COPY app_configurations (id, name, value, disabled, admin_id) FROM stdin;
1	notes field caption		f	15
3	menu research label		f	15
2	menu create master record label	New Player Record	f	15
4	hide search form simple	true	f	15
5	hide search form advanced	true	f	15
8	hide pro info	true	f	15
9	hide tracker panel	true	f	15
10	hide player tabs	true	f	15
11	show activity log panel	ipa_assignment	f	15
12	hide player accuracy	true	f	15
13	hide navbar search	true	f	15
7	default search form	Responses Needed	f	15
6	hide search form searchable reports	false	f	15
14	user session timeout	30	f	15
\.


--
-- Name: app_configurations_id_seq; Type: SEQUENCE SET; Schema: ml_app; Owner: -
--

SELECT pg_catalog.setval('app_configurations_id_seq', 14, true);


--
-- PostgreSQL database dump complete
--

