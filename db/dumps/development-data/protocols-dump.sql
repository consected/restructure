set search_path=ml_app;

begin
insert into admins (email, id) values ('noadmin@nodomain.com', 1);
end;
begin
insert into admins (email, id) values ('noadmin@nodomain.com', 3);
end;
begin
insert into admins (email, id) values ('noadmin@nodomain.com', 4);
end;
begin
insert into admins (email, id) values ('noadmin@nodomain.com', 6);
end;
begin
insert into admins (email, id) values ('noadmin@nodomain.com', 7);
end;

begin;

truncate protocols cascade;
truncate sub_processes cascade;
truncate protocol_events cascade;

SELECT pg_catalog.setval('protocols_id_seq', 1, true);
SELECT pg_catalog.setval('sub_processes_id_seq', 1, true);
SELECT pg_catalog.setval('protocol_events_id_seq', 1, true);




INSERT INTO protocols VALUES (3, 'General Awareness', '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, NULL, NULL);
INSERT INTO protocols VALUES (2, 'Q1', '2015-10-14 12:14:06.709367', '2015-10-14 16:16:19.386172', false, 1, NULL);
INSERT INTO protocols VALUES (4, 'Updates', '2015-10-14 16:16:56.095391', '2015-10-14 16:16:56.095391', NULL, 4, 100);
INSERT INTO protocols VALUES (1, 'Study', '2015-10-14 12:14:06.709367', '2015-10-14 16:16:56.87405', NULL, 4, 10);
INSERT INTO protocols VALUES (5, 'TeamStudy', '2016-02-08 18:01:46.400243', '2016-02-08 18:01:46.400243', false, 7, NULL);
INSERT INTO protocols VALUES (7, 'Law and Ethics', '2016-03-24 19:16:15.882808', '2016-03-24 19:16:15.882808', false, 7, NULL);
INSERT INTO protocols VALUES (6, 'Q1 Pilot', '2016-02-17 19:29:24.63238', '2016-07-06 16:15:18.654513', true, 7, 6);

INSERT INTO sub_processes VALUES (39, 'Complete', NULL, 2, NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367');
INSERT INTO sub_processes VALUES (32, 'Sent', NULL, 3, NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367');
INSERT INTO sub_processes VALUES (49, 'Bounced', NULL, 3, NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367');
INSERT INTO sub_processes VALUES (47, 'Sent', NULL, 2, NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367');
INSERT INTO sub_processes VALUES (6, 'Bounced', NULL, 2, NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367');
INSERT INTO sub_processes VALUES (8, 'Opt Out', NULL, 2, NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367');
INSERT INTO sub_processes VALUES (45, 'Unsubscribe', NULL, 3, NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367');
INSERT INTO sub_processes VALUES (50, 'Inquiry', NULL, 2, NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367');
INSERT INTO sub_processes VALUES (51, 'record updates', NULL, 4, 4, '2015-10-14 16:16:56.678974', '2015-10-14 16:16:56.678974');
INSERT INTO sub_processes VALUES (52, 'flag updates', NULL, 4, 4, '2015-10-14 16:16:56.832899', '2015-10-14 16:16:56.832899');
INSERT INTO sub_processes VALUES (53, 'Alerts', NULL, 1, 4, '2015-10-14 16:16:56.887813', '2015-10-14 16:16:56.887813');
INSERT INTO sub_processes VALUES (54, 'Opt Out', NULL, 1, 4, '2015-10-14 16:16:56.952748', '2015-10-14 16:16:56.952748');
INSERT INTO sub_processes VALUES (24, 'Comments', true, 1, 3, '2015-10-14 12:14:06.709367', '2015-10-14 18:10:13.161861');
INSERT INTO sub_processes VALUES (55, 'Inquiry', false, 3, 7, '2015-11-04 15:29:54.61419', '2015-11-04 15:29:54.61419');
INSERT INTO sub_processes VALUES (48, '(do not use) Reject', true, 2, 1, '2015-10-14 12:14:06.709367', '2015-11-04 19:43:31.819132');
INSERT INTO sub_processes VALUES (4, '(do not use) Player-message', true, 2, 1, '2015-10-14 12:14:06.709367', '2015-11-04 19:59:17.21258');
INSERT INTO sub_processes VALUES (34, 'Complete', true, 3, 1, '2015-10-14 12:14:06.709367', '2015-11-04 20:20:54.481335');
INSERT INTO sub_processes VALUES (56, 'Event', false, 3, 7, '2015-12-14 21:21:12.414697', '2015-12-14 21:21:12.414697');
INSERT INTO sub_processes VALUES (57, 'CIS-received', false, 1, 7, '2015-12-14 21:31:21.045159', '2015-12-14 21:31:21.045159');
INSERT INTO sub_processes VALUES (58, 'Inquiry', false, 5, 7, '2016-02-08 18:03:34.910301', '2016-02-08 18:03:34.910301');
INSERT INTO sub_processes VALUES (59, 'Sent', false, 6, 7, '2016-02-17 19:29:51.598135', '2016-02-17 19:29:51.598135');
INSERT INTO sub_processes VALUES (60, 'Complete', false, 6, 7, '2016-02-17 19:30:02.285632', '2016-02-17 19:30:02.285632');
INSERT INTO sub_processes VALUES (61, 'Opt Out', false, 6, 7, '2016-02-17 19:30:21.149181', '2016-02-17 19:30:21.149181');
INSERT INTO sub_processes VALUES (62, 'Opt Out ', false, 5, 6, '2016-03-17 18:24:42.699637', '2016-03-17 18:24:42.699637');
INSERT INTO sub_processes VALUES (63, 'Sent', false, 5, 7, '2016-03-24 19:13:36.871988', '2016-03-24 19:13:36.871988');
INSERT INTO sub_processes VALUES (64, 'Bounced', false, 5, 7, '2016-03-24 19:13:52.069484', '2016-03-24 19:13:52.069484');
INSERT INTO sub_processes VALUES (65, 'Received Consent', false, 5, 7, '2016-03-24 19:17:04.269411', '2016-03-24 19:20:58.633505');
INSERT INTO sub_processes VALUES (66, 'Q1 Received - Requires Follow up', false, 2, 7, '2016-04-11 15:00:55.471959', '2016-04-11 15:00:55.471959');
INSERT INTO sub_processes VALUES (67, 'Opt In', false, 2, 7, '2016-06-02 18:23:11.104385', '2016-06-02 18:23:11.104385');
INSERT INTO sub_processes VALUES (68, 'Opt In', false, 1, 6, '2016-06-14 20:04:54.756758', '2016-06-14 20:04:54.756758');
INSERT INTO sub_processes VALUES (69, 'Opt In', false, 3, 6, '2016-06-14 20:07:44.24321', '2016-06-14 20:07:44.24321');
INSERT INTO sub_processes VALUES (70, 'Opt In', false, 5, 6, '2016-06-14 20:10:04.241634', '2016-06-14 20:10:04.241634');
INSERT INTO sub_processes VALUES (71, 'Participation Inquiry', false, 7, 7, '2016-09-07 13:40:26.332775', '2016-09-07 13:40:26.332775');
INSERT INTO sub_processes VALUES (72, 'Completed', false, 7, 7, '2016-09-07 13:40:43.372157', '2016-09-07 13:40:43.372157');
INSERT INTO sub_processes VALUES (73, 'Opt Out', false, 7, 7, '2016-09-07 13:41:48.382508', '2016-09-07 13:41:48.382508');
INSERT INTO sub_processes VALUES (74, 'Ineligible', false, 2, 7, '2017-02-15 14:15:26.712244', '2017-02-15 14:15:26.712244');

INSERT INTO protocol_events VALUES (51, 'created address', 4, '2015-10-14 16:16:56.728404', '2015-10-14 16:16:56.728404', false, 51, NULL, NULL);
INSERT INTO protocol_events VALUES (52, 'created player contact', 4, '2015-10-14 16:16:56.745372', '2015-10-14 16:16:56.745372', NULL, 51, NULL, NULL);
INSERT INTO protocol_events VALUES (53, 'created player info', 4, '2015-10-14 16:16:56.759474', '2015-10-14 16:16:56.759474', NULL, 51, NULL, NULL);
INSERT INTO protocol_events VALUES (54, 'created scantron', 4, '2015-10-14 16:16:56.772143', '2015-10-14 16:16:56.772143', NULL, 51, NULL, NULL);
INSERT INTO protocol_events VALUES (55, 'updated address', 4, '2015-10-14 16:16:56.784156', '2015-10-14 16:16:56.784156', false, 51, NULL, NULL);
INSERT INTO protocol_events VALUES (56, 'updated player contact', 4, '2015-10-14 16:16:56.796196', '2015-10-14 16:16:56.796196', false, 51, NULL, NULL);
INSERT INTO protocol_events VALUES (57, 'updated player info', 4, '2015-10-14 16:16:56.808402', '2015-10-14 16:16:56.808402', false, 51, NULL, NULL);
INSERT INTO protocol_events VALUES (58, 'updated scantron', 4, '2015-10-14 16:16:56.822374', '2015-10-14 16:16:56.822374', NULL, 51, NULL, NULL);
INSERT INTO protocol_events VALUES (59, 'created player info', 4, '2015-10-14 16:16:56.846647', '2015-10-14 16:16:56.846647', NULL, 52, NULL, NULL);
INSERT INTO protocol_events VALUES (60, 'updated player info', 4, '2015-10-14 16:16:56.859674', '2015-10-14 16:16:56.859674', false, 52, NULL, NULL);
INSERT INTO protocol_events VALUES (61, 'Level 1', 4, '2015-10-14 16:16:56.903424', '2015-10-14 16:16:56.903424', false, 53, 'always-notify-user', ' It is strongly recommended to avoid contact with this person. If receiving a call, attempt to redirect to a supervisor immediately.');
INSERT INTO protocol_events VALUES (64, 'Resolved', 4, '2015-10-14 16:16:56.942148', '2015-10-14 16:16:56.942148', NULL, 53, NULL, NULL);
INSERT INTO protocol_events VALUES (33, 'Reminder - Mail', 3, '2015-10-14 12:14:06.709367', '2015-10-14 18:18:12.395789', true, 39, '', '');
INSERT INTO protocol_events VALUES (7, 'Thank You', 3, '2015-10-14 12:14:06.709367', '2015-10-14 18:18:25.717486', true, 39, '', '');
INSERT INTO protocol_events VALUES (50, 'Inquiry Active', 3, '2015-10-14 12:14:06.709367', '2015-10-14 18:24:06.563743', true, 50, '', '');
INSERT INTO protocol_events VALUES (12, 'Redcap', 3, '2015-10-14 12:14:06.709367', '2015-10-14 18:31:36.453019', true, 47, '', '');
INSERT INTO protocol_events VALUES (66, 'T-Shirts', 3, '2015-10-14 18:12:17.102784', '2015-10-26 15:37:34.473434', false, 49, 'notify-user', 'Mail to this address has been returned. Update the address record to mark as bad contact.');
INSERT INTO protocol_events VALUES (67, 'T-shirt', 7, '2015-11-04 15:30:28.738177', '2015-11-04 15:30:28.738177', false, 55, '', '');
INSERT INTO protocol_events VALUES (68, 'Complete', 7, '2015-11-04 15:31:03.760946', '2015-11-04 15:31:03.760946', false, 55, '', '');
INSERT INTO protocol_events VALUES (39, 'Phone', 1, '2015-10-14 12:14:06.709367', '2015-11-04 20:04:07.755053', true, 39, '', '');
INSERT INTO protocol_events VALUES (43, 'Prenotification', 1, '2015-10-14 12:14:06.709367', '2015-11-04 20:04:24.000154', true, 39, '', '');
INSERT INTO protocol_events VALUES (34, 'Sumo Card', 1, '2015-10-14 12:14:06.709367', '2015-11-04 20:20:41.880028', true, 34, '', '');
INSERT INTO protocol_events VALUES (46, 'Mail', 1, '2015-10-14 12:14:06.709367', '2015-11-04 20:20:47.612727', true, 34, '', '');
INSERT INTO protocol_events VALUES (5, 'Mail', 1, '2015-10-14 12:14:06.709367', '2015-11-04 20:26:23.83807', false, 49, 'notify-user', 'Mail to this address has been returned. Update the address record to mark as bad contact.');
INSERT INTO protocol_events VALUES (69, 'created sage assignment', 1, '2015-11-17 15:14:59.04701', '2015-11-17 15:14:59.04701', false, 51, '', '');
INSERT INTO protocol_events VALUES (70, 'updated sage assignment', 1, '2015-11-17 15:15:18.282733', '2015-11-17 15:15:18.282733', false, 51, '', '');
INSERT INTO protocol_events VALUES (73, 'Las Vegas', 7, '2015-12-14 21:21:29.095404', '2015-12-14 21:21:29.095404', false, 56, '', '');
INSERT INTO protocol_events VALUES (74, 'REDCap', 7, '2015-12-14 21:31:38.884596', '2015-12-14 21:31:38.884596', false, 57, '', '');
INSERT INTO protocol_events VALUES (75, 'Event', 7, '2015-12-14 21:32:16.817621', '2015-12-14 21:32:16.817621', false, 57, '', '');
INSERT INTO protocol_events VALUES (76, 'Paper', 7, '2015-12-14 21:32:41.173966', '2015-12-14 21:32:41.173966', false, 57, '', '');
INSERT INTO protocol_events VALUES (77, 'Phone', 7, '2015-12-14 21:32:48.775493', '2015-12-14 21:32:48.775493', false, 57, '', '');
INSERT INTO protocol_events VALUES (78, 'Email', 7, '2015-12-14 21:33:01.322081', '2015-12-14 21:33:01.322081', false, 57, '', '');
INSERT INTO protocol_events VALUES (79, 'Other', 7, '2016-01-06 19:36:19.249412', '2016-01-11 20:51:03.982758', true, 57, '', '');
INSERT INTO protocol_events VALUES (80, 'REDCap', 7, '2016-02-17 19:30:53.744082', '2016-02-17 19:30:53.744082', false, 59, '', '');
INSERT INTO protocol_events VALUES (81, 'Scantron', 7, '2016-02-17 19:31:23.219144', '2016-02-17 19:31:23.219144', false, 59, '', '');
INSERT INTO protocol_events VALUES (82, 'Phone From Staff', 6, '2016-03-17 14:29:12.464959', '2016-03-17 14:29:12.464959', false, 58, '', '');
INSERT INTO protocol_events VALUES (83, 'Phone From Player', 6, '2016-03-17 14:30:08.934195', '2016-03-17 14:30:08.934195', false, 58, '', '');
INSERT INTO protocol_events VALUES (84, 'Complete ', 6, '2016-03-17 14:30:25.343012', '2016-03-17 14:30:25.343012', false, 58, '', '');
INSERT INTO protocol_events VALUES (85, 'Email From Player', 6, '2016-03-17 14:30:46.294107', '2016-03-17 14:30:46.294107', false, 58, '', '');
INSERT INTO protocol_events VALUES (86, 'Email From Staff', 6, '2016-03-17 14:31:11.430712', '2016-03-17 14:31:11.430712', false, 58, '', '');
INSERT INTO protocol_events VALUES (87, 'Andriod Phone', 6, '2016-03-17 18:25:59.169462', '2016-03-17 18:25:59.169462', false, 58, '', '');
INSERT INTO protocol_events VALUES (88, 'TeamStudy ID', 7, '2016-03-24 19:14:29.672109', '2016-03-24 19:14:29.672109', false, 63, '', '');
INSERT INTO protocol_events VALUES (89, 'TeamStudy ID', 7, '2016-03-24 19:14:48.903031', '2016-03-24 19:14:48.903031', false, 64, '', '');
INSERT INTO protocol_events VALUES (90, 'Scantron', 7, '2016-04-11 15:01:42.749489', '2016-04-11 15:01:42.749489', false, 66, '', '');
INSERT INTO protocol_events VALUES (28, 'Sumo Card', 7, '2015-10-14 12:14:06.709367', '2016-06-02 18:21:30.193984', true, 32, '', '');
INSERT INTO protocol_events VALUES (65, 'Q1 Email', 7, '2015-10-14 17:59:34.5131', '2016-06-02 18:21:45.728093', false, 32, '', '');
INSERT INTO protocol_events VALUES (25, 'Q1 Mail', 7, '2015-10-14 12:14:06.709367', '2016-06-02 18:22:00.882078', false, 32, '', '');
INSERT INTO protocol_events VALUES (97, 'Reminder - Email', 6, '2016-06-07 14:22:06.608281', '2016-06-07 14:22:06.608281', false, 47, '', 'Reminder sent out using email ');
INSERT INTO protocol_events VALUES (91, 'Reminder - Email', 6, '2016-04-21 18:03:12.968218', '2016-06-07 14:57:04.767903', false, 63, '', 'Reminder has been sent out via email.');
INSERT INTO protocol_events VALUES (98, 'Ambassador Email', 6, '2016-06-07 16:25:45.428625', '2016-06-07 16:25:45.428625', false, 32, '', 'Ambassador Email will be replacing the 71, 93, 95');
INSERT INTO protocol_events VALUES (93, 'Mama Mc Nab Email', 6, '2016-05-02 17:42:37.417161', '2016-06-07 17:32:06.723154', true, 32, '', 'Mama Mac Nab Email set ');
INSERT INTO protocol_events VALUES (71, 'Joe Horn Email', 6, '2015-11-18 19:21:21.766815', '2016-06-07 17:32:10.884309', true, 32, '', '');
INSERT INTO protocol_events VALUES (21, 'Email from Staff', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 50, NULL, NULL);
INSERT INTO protocol_events VALUES (19, 'REDCap', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 6, NULL, NULL);
INSERT INTO protocol_events VALUES (41, 'Phone from Staff', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 50, NULL, NULL);
INSERT INTO protocol_events VALUES (11, 'Phone from Player', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 50, NULL, NULL);
INSERT INTO protocol_events VALUES (42, 'Thank You', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 6, NULL, NULL);
INSERT INTO protocol_events VALUES (37, 'Prenotification', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 47, NULL, NULL);
INSERT INTO protocol_events VALUES (10, 'Inquiry Complete', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 50, NULL, NULL);
INSERT INTO protocol_events VALUES (27, 'Reminder - Mail', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 47, NULL, NULL);
INSERT INTO protocol_events VALUES (31, 'Scantron', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 47, NULL, NULL);
INSERT INTO protocol_events VALUES (48, 'Scantron', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 48, NULL, NULL);
INSERT INTO protocol_events VALUES (35, 'REDCap', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 39, NULL, NULL);
INSERT INTO protocol_events VALUES (16, 'Phone', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 4, NULL, NULL);
INSERT INTO protocol_events VALUES (6, 'Prenotification', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 6, NULL, NULL);
INSERT INTO protocol_events VALUES (2, 'Thank You', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 47, NULL, NULL);
INSERT INTO protocol_events VALUES (22, 'Reminder - Mail', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 6, NULL, NULL);
INSERT INTO protocol_events VALUES (3, 'Scantron', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 6, NULL, NULL);
INSERT INTO protocol_events VALUES (36, 'Scantron', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 39, NULL, NULL);
INSERT INTO protocol_events VALUES (23, 'REDCap', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 48, NULL, NULL);
INSERT INTO protocol_events VALUES (4, 'REDCap', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 4, NULL, NULL);
INSERT INTO protocol_events VALUES (26, 'T-Shirt', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 32, NULL, NULL);
INSERT INTO protocol_events VALUES (18, 'Email from Player', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 50, NULL, NULL);
INSERT INTO protocol_events VALUES (29, 'REDCap', NULL, '2015-10-14 12:14:06.709367', '2015-10-14 12:14:06.709367', NULL, 47, NULL, NULL);
INSERT INTO protocol_events VALUES (49, 'Email', 7, '2015-10-14 12:14:06.709367', '2016-06-08 19:32:00.006385', false, 49, 'notify-user', 'Email to this address has been returned. Update the email record to mark as bad contact.');
INSERT INTO protocol_events VALUES (62, 'Level 2', 7, '2015-10-14 16:16:56.918574', '2016-06-08 19:33:20.48701', false, 53, 'always-notify-user', ' It is strongly recommended to avoid contact with this person. If receiving a call, attempt to redirect to a supervisor immediately.');
INSERT INTO protocol_events VALUES (72, 'Joe Horn Email', 7, '2015-11-18 19:25:09.342324', '2016-07-06 16:06:20.833279', true, 49, 'notify-user', 'Mail to this address has been returned. Update the address record to mark as bad contact.');
INSERT INTO protocol_events VALUES (94, 'Mama Mc Nab Email', 7, '2016-05-02 17:44:59.761487', '2016-07-06 16:06:31.846427', true, 49, '', 'Mama Mc Nab Email Bounced');
INSERT INTO protocol_events VALUES (96, 'Rodney Peete Email', 7, '2016-06-01 16:35:54.250941', '2016-07-06 16:06:50.400202', true, 49, '', 'Email to this address has been returned. Update the email record to mark as bad contact.');
INSERT INTO protocol_events VALUES (20, 'Sumo Card', 7, '2015-10-14 12:14:06.709367', '2016-07-06 16:07:02.140552', true, 49, 'notify-user', 'Mail to this address has been returned. Update the address record to mark as bad contact.');
INSERT INTO protocol_events VALUES (95, 'Rodney Peete Email', 7, '2016-06-01 16:34:02.889134', '2016-07-06 16:07:53.947908', true, 32, '', 'Peete - advisor- email sent');
INSERT INTO protocol_events VALUES (92, 'Reminder', 7, '2016-05-02 15:58:21.698181', '2016-07-06 16:13:07.783687', true, 64, '', 'when Team Study Email reminder is Bunced');
INSERT INTO protocol_events VALUES (63, 'Level 3', 7, '2015-10-14 16:16:56.930336', '2016-06-08 19:33:36.415772', false, 53, 'always-notify-user', ' It is strongly recommended to avoid contact with this person. If receiving a call, attempt to redirect to a supervisor immediately.');
INSERT INTO protocol_events VALUES (100, 'Email', 6, '2016-06-23 20:24:37.037633', '2016-06-23 20:24:37.037633', false, 6, '', '');
INSERT INTO protocol_events VALUES (99, 'Reminder- Email', 7, '2016-06-23 20:22:23.210778', '2016-07-06 16:14:09.295768', false, 64, '', 'Use for the TeamStudy Bounce email for future and we might disable the Reminder and TeamStudy ID');
INSERT INTO protocol_events VALUES (101, 'Complete', 7, '2017-02-15 14:16:07.720691', '2017-02-15 14:16:07.720691', false, 74, '', 'For players that have completed Q1 but were ineligible - their data has been erased per IRB protocol.');
INSERT INTO protocol_events VALUES (102, 'Mail', 7, '2017-04-20 19:19:39.769909', '2017-04-20 19:19:39.769909', false, 32, '', '');
INSERT INTO protocol_events VALUES (103, 'Study Updates', 7, '2017-04-20 19:20:06.073024', '2017-04-20 19:20:06.073024', false, 32, '', '');


SELECT pg_catalog.setval('protocol_events_id_seq', 103, true);
SELECT pg_catalog.setval('sub_processes_id_seq', 74, true);
SELECT pg_catalog.setval('protocols_id_seq', 7, true);
end;
