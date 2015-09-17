set SEARCH_PATH=ml_app,ml_work;

insert into admins (email) values 'auto-admin';


drop table tracker_full;
drop table tracker_migration_lookup;
drop table tracker_migration_lookup_ids;
drop table tracker_latest;
drop table tracker_hist_only;

delete from ml_app.tracker_history;
delete from ml_app.trackers;
delete from ml_app.protocol_events;
delete from ml_app.sub_processes;
delete from ml_app.protocols;
/*delete from masters;*/


/* Create the master list of msids - note this picks only the distinct msid entries,*/
/*insert into masters (msid, pro_id) select distinct msid, pro_id from ml_copy where msid is not null and (accuracy_score is null or accuracy_score <> -1 and accuracy_score <> 999);
*/


/* Generate a full set of tracker records */
select *  into temp tracker_full from ml_work.tracker union select * from ml_work.tracker_history ;

/* Get rid of records not in the masters table) */
delete from tracker_full tf1 where not exists (select masters.msid from masters where masters.msid = tf1.msid);

/* add a serial column so we can match records in a moment */
alter table tracker_full add column id serial;
alter table tracker_full add column new_event_date timestamp;
alter table tracker_full add column protocol_id integer;
alter table tracker_full add column sub_process_id integer;
alter table tracker_full add column protocol_event_id integer;
alter table tracker_full add column protocol_name varchar;
alter table tracker_full add column sub_process_name varchar;
alter table tracker_full add column protocol_event_name varchar;

update tracker_full tf set 
    protocol_name = 
        case 
            when strpos(tf.event, 'General Awareness') = 1 then 'General Awareness'          
            when event is NULL then '??????????????????????????????????'
            else 'Q1' 
        end
    ,
    sub_process_name = 
        case             
            when strpos(event, 'General Awareness') = 1 then 
                case 
                    when outcome is NULL then 'Sent'
                    when trim(outcome) = 'Active' then 'Sent'
                    when trim(outcome) = 'Pending' then 'Sent'
                    when trim(outcome) = 'Opt Out' then 'Opt Out'
                    when trim(outcome) = 'Bounced' then 'Bounced'
                    else trim(outcome)
                end
            else
                case 
                    when trim(event) = 'Inquiry' then 'Inquiry'

                    when trim(outcome) = 'Opt Out' then 'Opt Out'
                    when trim(outcome) = 'Bounced' then 'Bounced'
                    when trim(outcome) = 'Complete' then 'Complete'
                    when trim(outcome) = 'Active' then 'Sent'
                    when trim(outcome) = 'Pending' then 'Sent'
                    when outcome IS NULL then 'Sent'
                    else trim(outcome)
                end
        end
    ,
    protocol_event_name = 
        case 
            when strpos(event, 'General Awareness') = 1 then 
                case 
                    when outcome IS NULL or trim(outcome) = 'Opt Out' then NULL                    
                    else trim(c_method)
                end
            else
                case                     
                    when trim(outcome) = 'Opt Out' then NULL
                    when trim(event) = 'Inquiry' AND trim(outcome) =  'Staff-message' then  trim(c_method) || ' from Staff'
                    when trim(event) = 'Inquiry' AND trim(outcome) =  'Player-message' then  trim(c_method) || ' from Player'    
                    when trim(event) = 'Inquiry' AND trim(outcome) =  'Complete' then  'Inquiry Complete'
                    when trim(event) = 'Inquiry' then 'Inquiry ' || trim(outcome)
                    when trim(event) = 'Prenotification' then 'Prenotification' 
                    when trim(event) = 'R1' then 'Reminder - Mail' 
                    when trim(event) = 'Thank You' then 'Thank You' 
                    when trim(c_method) = 'Scantron' OR trim(c_method) = 'Mail' then 'Scantron'
                    when trim(c_method) = 'REDCap' OR trim(c_method) = 'Email' then 'REDCap'
                    when outcome IS NULL OR c_method IS NULL then NULL
                    
                    else trim(c_method)                    
            end
        end
    
;


/* Prepare the protocols / sub_processes / protocol_events */
select distinct ROW_NUMBER() over () "id", 
  protocol_name,
  1 "protocol_id", 
  sub_process_name, 
  2 "sub_process_id", 
  protocol_event_name
into temporary tracker_migration_lookup
from tracker_full group by protocol_name, sub_process_name, protocol_event_name, trim(outcome);

/* Make a protocol_id number for each protocol name */
update tracker_migration_lookup set protocol_id = 1 where protocol_name = 'Q1';
/*update tracker_migration_lookup set protocol_id = 2 where protocol_name = 'R1';*/
update tracker_migration_lookup set protocol_id = 3 where protocol_name = 'General Awareness';
update tracker_migration_lookup set protocol_id = 4 where protocol_name = 'Inquiry';
 
/* create the remaining ids for sub_process and process_event */
select protocol_name, protocol_id, sub_process_name, first_value(id) over(partition by protocol_id, sub_process_name) "sub_process_id", protocol_event_name, id "event_id" 
into temp tracker_migration_lookup_ids from tracker_migration_lookup order by protocol_id, sub_process_name;


/* make the inserts into the lookup tables */
insert into protocols (id, name, created_at, updated_at) select distinct protocol_id, protocol_name, now(), now() from tracker_migration_lookup_ids;
insert into sub_processes(id, name, created_at, updated_at, protocol_id) select distinct sub_process_id, sub_process_name, now(), now(), protocol_id from tracker_migration_lookup_ids group by sub_process_name, sub_process_id, protocol_id;
insert into protocol_events(id, name, created_at, updated_at, sub_process_id) select  event_id, protocol_event_name, now(), now(), sub_process_id from tracker_migration_lookup_ids ;

/* force the sequences to update correctly */
SELECT setval('protocols_id_seq', (SELECT MAX(id) FROM protocols));
SELECT setval('sub_processes_id_seq', (SELECT MAX(id) FROM sub_processes));
SELECT setval('protocol_events_id_seq', (SELECT MAX(id) FROM protocol_events));


/* set the id  for protocol, sub process and protocol event in the temp tracker_full table */

/* get the protocol_id for the calculated protocol name */

update tracker_full tf set protocol_id = (select distinct id from protocols where protocols.name = tf.protocol_name );

/* get the sub_process_id for the calculated sub process name */
update tracker_full tf set sub_process_id = (select distinct id from sub_processes where sub_processes.name = tf.sub_process_name and tf.protocol_id = sub_processes.protocol_id);

/* get the protocol_event_id for the calculated protocol event name */
update tracker_full tf set protocol_event_id = ( select distinct id from protocol_events where protocol_events.name = tf.protocol_event_name and tf.sub_process_id =  protocol_events.sub_process_id);


/* generate the event date for the new tracker - use the first one available from the following:  outcome_date, event_date, lastmod */
update tracker_full set new_event_date = case when outcome_date is not null then outcome_date when event_date is not null then event_date else lastmod end ;



/* pull the latest tracker entry for each msid / protocol pair */
select distinct on (msid, protocol_id) id, msid, new_event_date into temp tracker_latest from tracker_full order by msid, protocol_id, new_event_date desc, id;


/* now insert the latest records into tracker */
insert into ml_app.trackers 
(master_id, protocol_id, event_date, created_at, updated_at, sub_process_id, protocol_event_id)
select 
masters.id, tf.protocol_id, tf.event_date, now(), now(), tf.sub_process_id, tf.protocol_event_id
from tracker_full tf
inner join tracker_latest on tracker_latest.id = tf.id 
inner join masters on masters.msid = tracker_latest.msid;

/* clear the tracker_history */
delete from ml_app.tracker_history;

/* Now go and add the history items that were not in the 'latest' set.
 * Add these, linking the tracker_id back to the matching tracker record created above that has a matching msid and protocol pair
 * We create a temp table to allow comparison of results in the checks below
 */

select masters.id "master_id", tf.protocol_id "protocol_id", tf.event_date "event_date", now() "created_at", now() "updated_at", 
tf.sub_process_id "sub_process_id", tf.protocol_event_id "protocol_event_id", trackers.id "tracker_id", trackid
into temp tracker_hist_only
from tracker_full tf 
inner join masters on masters.msid = tf.msid
inner join trackers on trackers.master_id = masters.id and trackers.protocol_id = tf.protocol_id
where not exists ( select id from tracker_latest tl where tl.id = tf.id);

/* Careful ordering of records is required to ensure appropriate retrieval for tracker history
   Records must be inserted in order so tracker_history.id increments correctly. To ensure chronology, we 
   order finally by trackid (the original tracker sequence id) to ensure that matching event dates can be appropriately ordered
   based on the order they were entered originally.
*/
insert into ml_app.tracker_history 
(master_id, protocol_id, event_date, created_at, updated_at, sub_process_id, protocol_event_id, tracker_id)
select master_id, protocol_id, event_date, created_at, updated_at, sub_process_id, protocol_event_id, tracker_id
from tracker_hist_only order by event_date desc, trackid;

/* Finally, force the latest tracker items back into the tracker_history */
update trackers set updated_at = now();

/* Now validate the results */


/* Initial checks on master list records */
select count(*) from ml_copy;
/*-------
 34902
*/

select count(distinct msid) from ml_copy;
/*-------
 23189
*/

/* The number of master records we expect */
select count(*) from (select distinct msid, pro_id from ml_copy where msid is not null and (accuracy_score is null or accuracy_score <> -1 and accuracy_score <> 999)) as t;
/*-------
 21624
*/

/* The actual number of masters records */
select count(*) from masters;
/*-------
 21624
*/

select count(distinct msid) from masters;
/*-------
 16935
*/


/* Get counts of msid / accuracy_score categories from ml_copy */
select case when accuracy_score is null then 'accuracy score null' when msid is null then 'msid null: ' || accuracy_score else 'msid exists: ' || accuracy_score end "rule", count(*) from ml_copy where msid is null or accuracy_score = -1 or accuracy_score = 999 or accuracy_score is null group by accuracy_score, rule;
/*
        rule         | count 
---------------------+-------
 accuracy score null |     1
 msid exists: -1     |  6244
 msid null: -1       |  6334
 msid exists: 999    |   700
*/
    

/* Total to reject (not including any null accuracy scores) */
select count(*) from ml_copy where msid is null or (accuracy_score is not null and (accuracy_score = -1 or accuracy_score = 999)); 
/*-------
 13278
*/

/* which means that masters should eventually contain */
select count(*) from ml_copy where not(msid is null or (accuracy_score is not null and (accuracy_score = -1 or accuracy_score = 999))); 
/*-------
 21624
*/

/* masters represents all master list records from the previous query - the numbers should match */
select count(*) from masters;
/*-------
 21624
*/

/* Validate that the master list plus the rejected list matches the total for ml_copy */
select (select count(*) from masters) + (select count(*) from ml_copy where msid is null or (accuracy_score is not null and (accuracy_score = -1 or accuracy_score = 999))) - (select count(*) from ml_copy) "result";
/*
 result 
--------
      0
*/


/* -----------------------------
 *  tracker list validations 
 * -----------------------------*/


/* check trackers and tracker_latest have corresponding numbers */
select count(*) from tracker_latest;
/*-------
 29360
*/

select count(*) from trackers;
/*-------
 29367
*/

/* They don't match... because of a strange inner join effect ... This is what is happening...*/
/* the original query that populated tracker_latest returns the expected number of rows */
select count(*) from (select distinct on (msid, protocol_id) id, msid, new_event_date from tracker_full order by msid, protocol_id, event_date desc, id) as t;
/*-------
 29360
*/
/* But when joined with the masters table to allow association with a masters.id, the count jumps by 7 */
select count(*) from tracker_latest inner join masters on masters.msid = tracker_latest.msid;
/*-------
 29367
*/


/* Find the duplicates, based on the joined masters table */
select distinct tlo.id, tlo.msid, mo.pro_id from tracker_latest tlo  inner join masters mo on mo.msid = tlo.msid where tlo.id in (select tl.id from tracker_latest tl inner join masters on masters.msid = tl.msid  group by tl.id having count(1) > 1) order by tlo.msid;
/*
  id   |  msid  | pro_id 
-------+--------+--------
 57738 | 108973 |    267
 57738 | 108973 |    268
 48315 | 114535 |   9267
 48315 | 114535 |   9268
 57767 | 119562 |   6662
 57767 | 119562 |   6663
 47352 | 122502 |   9659
 47352 | 122502 |   9660
 47352 | 122502 |   9661
 47352 | 122502 |   9665
 47352 | 122502 |   9753
(11 rows)
*/

/* Here we have 11 rows that have an msid that appears duplicated after the join. 4 msids are affected. If the MSIDs were unique 
   we would expect one record for each of the 4 msids to have made it in to trackers.
   The remainder are the 7 additional records that we see after the join.
*/


/* to test this, create a temporary list of unique msids in the masters table. The result should be that the temporary
    tracker_latest and trackers tables should now match. */
select distinct on(msid) id, msid, pro_id  into temp unique_masters from masters;

select 
   (select count(*) from tracker_latest) "latest", 
   (select count(*) from trackers inner join unique_masters on unique_masters.id = trackers.master_id) "trackers";
/* 
 latest | trackers 
--------+----------
  29360 |    29360
*/


/* tracker history count should =  
  records inserted into ml_app.trackers
+ records inserted directly in ml_app.tracker_history
*/

select (select count(*) from ml_app.trackers) "trackers", '+', 
  (select count(*) from tracker_hist_only) "history only", '=', 
  (select count(*) from trackers) + (select count(*) from tracker_hist_only) "total", 'matches?', 
  (select count(*) from ml_app.tracker_history) "tracker history";
/*
 trackers | ?column? | history only | ?column? | total | ?column? | tracker history 
----------+----------+--------------+----------+-------+----------+-----------------
    29367 | +        |        28429 | =        | 57796 | matches? |           57796
*/


/* In a perfect world, tracker_full (the full set of original tracker data with the items missing MSIDs discarded) will match the entries in 
   ml_app.tracker_history 
   We are seeing 8 additional records in ml_app.tracker_history after migration.

   We know that 7 additional records appear in trackers than due to duplicate msids, leaving just one unaccounted for.

*/
select count(*) + 7 from tracker_full;
/*-------
 57795
*/

/* we also have a mismatch between the number of actual records pushed directly into ml_app.tracker_history and the 
   expected records, due to the dup msids in masters.
   This accounts for the additional 1 record we're seeing in the full set of tracker records compared to tracker_full.

 */
select (select count(*) from tracker_hist_only) - (select count(*) from tracker_hist_only tho inner join unique_masters on unique_masters.id = tho.master_id) "diff";
/* diff 
------
    1
*/



/* Check that original and new tracker(s) tables have the correct number of records 
> tracker_full represents the union of ml_work tracker and tracker_history tables, with records missing from masters removed 
  We expect this value to be 0 (although currently it isn't)

*/
select (select count(*) from ml_app.tracker_history) - (select count(*) from tracker_full) "result";


/* Check that there are no fields we have not transferred. The result should be 0 */
select count(*) from tracker where emid is not null or addrid is not null or resent is not null or ty_method is not null or ty_sent is not null;



/* check the results in both directions */
select count(*) from ml_app.tracker_history th  where  not exists (select trackid from tracker_full tf inner join masters on masters.msid = tf.msid where masters.id = th.master_id );

select count(*) from tracker_full tf inner join masters on masters.msid = tf.msid where not exists (select id from ml_app.tracker_history th  where masters.id = th.master_id );

